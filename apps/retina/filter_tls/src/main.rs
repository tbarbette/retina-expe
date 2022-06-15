use retina_core::config::load_config;
use retina_core::subscription::TlsHandshake;
use retina_core::Runtime;
use retina_filtergen::filter;

use std::fs::File;
use std::io::{BufWriter, Write};
use std::path::PathBuf;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Mutex;

use anyhow::Result;
use clap::Parser;

use lazy_static::lazy_static;
use perthread::{PerThread, ThreadMap};

// Set up the map of per-thread counters
lazy_static! {
    static ref COUNTERS: ThreadMap<usize> = ThreadMap::default();
}

// Declare a specific per-thread counter
thread_local! {
    static COUNTER: PerThread<usize> = COUNTERS.register(0);
}



// Define command-line arguments.
#[derive(Parser, Debug)]
struct Args {
    #[clap(short, long, parse(from_os_str), value_name = "FILE")]
    config: PathBuf,
    #[clap(
        short,
        long,
        parse(from_os_str),
        value_name = "FILE",
        default_value = "tls.jsonl"
    )]
    outfile: PathBuf,
}

// Address of the HTTP server
#[filter("tls.sni ~ '10.100.0.2'")]
fn main() -> Result<()> {
    env_logger::init();
    let args = Args::parse();
    let config = load_config(&args.config);

    // Use `BufWriter` to improve the speed of repeated write calls to the same file.
    let file = Mutex::new(BufWriter::new(File::create(&args.outfile)?));
    let cnt = AtomicUsize::new(0);

    let callback = |tls: TlsHandshake| {
        let tls_tuple = (tls.five_tuple, match tls.data.client_hello {
            Option::Some(val) => val.server_name,
            Option::None => Some(String::from("No client hello"))
        });
        if let Ok(serialized) = serde_json::to_string(&tls_tuple) {
            let mut wtr = file.lock().unwrap();
            wtr.write_all(serialized.as_bytes()).unwrap();
            wtr.write_all(b"\n").unwrap();
            cnt.fetch_add(1, Ordering::Relaxed);
            
        }
    };
    let mut runtime = Runtime::new(config, filter, callback)?;
    runtime.run();

    let mut wtr = file.lock().unwrap();
    wtr.flush()?;
    COUNTER.with(|c|
    println!(
        "Done. Logged {:?} TLS handshakes to {:?}",
        c, &args.outfile
    ));
    Ok(())
}
