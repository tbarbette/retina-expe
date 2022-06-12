# Retina experiments

This repository contains the scripts to run an experiment of the [Retina](https://github.com/stanford-esrg/retina) paper. 

For most experiments we used a TAP on the Stanford traffic. For the Figure 6 experiment we used 2 machines in a client/server scenario, and a third machine acting as a TAP between those machines.

The experiment manager is [NPF](https://github.com/tbarbette/npf), allowing to easily deploy the scripts over a cluster, and re-run experiments for multiple points and variables. In this experiment we will, as in the paper, augment the offered HTTP load and see how competing solutions perform.

Before running the experiments, you need to prepare your testbed according to the following guidelines.

## Physical testbed
For the results in the paper, we used our own 100G machines. We propose to use CloudLab, a publicly available machine provider for research purpose.
In any cases you need Mellanox NICs (ConnectX 4-7 or BlueField 1-2), hardware support for other NICs is untested.

### CloudLab
The profile used for the machines is available at ( https://www.cloudlab.us/show-profile.php?uuid=82d026d4-e992-11ec-aacb-e4434b2381fc ). 

This profile will build a ring of 3 machines. Both client and server use their second interface to mirror packets to the dut running retina. The machine uses Ubuntu 20.04, we recommend doing the same.

Create an account on (https://www.cloudlab.us/) then follow the link above and click on "instanciate".
The profile has a parameter to set the machine type. You should select d6515 machines to have a 100G experiment. If none are available, then in general the c6525-25g are available. However it will run at 25G.
No need to give a name to the experiment then click on Finish. The profile will automatically launch the bootstrap.sh script to install everything on all machines.  After a dozen minutes, you will get the SSH command to jump to the server.

#### Verify the cloudlab image works
	
	cd /local/retina-expe/
	cat /local/logs/startup.log

Verify the last line is "Boostrap finished!", if not the script may still be running.

## Software

We recommand using Ubuntu 20.04 as this is what we used for all experiments.

### Automatic
We recommand running ./bootstrap.sh on all machines to install all dependencies at once. This will only work with Ubuntu (preferably 20.04).
This is already done with the Cloudlab image.

### Manual

#### Network Performance Framework (NPF) Tool

You can install npf via the following command:

    python3 -m pip install --user npf

Do not forget to add export PATH=$PATH:~/.local/bin to ~/.bashrc or ~/.zshrc. Otherwise, you cannot run npf-compare and npf-run commands.

NPF will look for cluster/ and repo/ in your current working/testie directory. We have included the required repo for our experiments and a sample cluster template, available at experiment/. To setup your cluster, please check the guidelines for our previous paper. Additionally, you can check the NPF documentation at https://npf.readthedocs.io/.

#### Mellanox OFED
#### DPDK
#### Rust
#### Retina
#### Suricata

## Running the experiment
Our experiments uses NPF, a tool to manage experiments, run the tests over a cluster and collect results.

### Configuring NPF
NPF needs passwordless sudo access through SSH to all machines. This is already provided if using the CloudLab image.

### Details about NPF
NPF uses a test description files that gives variables, scripts, setup phase, where to run what, ... It is in this repository "http.npf".

At first run, NPF itself will build some dependencies by itself, such as FastClick to compute baseline speeds and WRK to generate HTTP load.
Then NPF will run some init scripts on all machines. Installing NGINX on "server", configuring  IPs, ...

Then for values of given variables, NPF will run scripts on all machines. In the first experiment for intance we re-run the same test but with 25 generation rates. Each test is run 3 times. And this is done for all "series" (baseline, Retina, Suricata, ... think of it as lines in your line graph)

Then some cleanup python scripts are done after each runs, to parse results from logs and export it in the NPF format.

After all tests, NPF will automatically produce some graph. You can add --output out.csv to generate some CSVs.

### Running NPF

Here is each argument of the command line explained line by line:
```
	npf-compare 
	 "local+fastclick,SAMPLE=pkt_count:Link speed" #The first serie to try : a baseline that only counts packets
	  local+retina:Retina #The second serie : Retina itself
	  --test http.npf #The test script
	  --cluster #The NPF scripts define "roles" such as client and servers. Here you tell which machine will take which roles.
			client=node-0-ctrl,nfs=0 #The "client" will be the machine named node-0-ctrl. It is not using NFS so we have to copy everything to the machine
			server=node-1-ctrl,nfs=0
			dut=node-2-ctrl,nfs=0
	--show-full  #Show stdout and stderr in live, will create a lot of outputs but will tell you what's happening
	--show-cmd  #Show the command launched and where
	--variables #Override a few variables that will define parameters of the experiment
		 "CPU=1" #Number of CPU to use
		 "SAMPLE=log_tls" #The test app to run
		 "DPDK_PATH=$DPDK_PATH" #Env variables will not pass through ssh and sudo. We have to pass them explicitely
	--graph-filename ssl.pdf # basename for the generated graphs
	--tags ssl tls rate high #Tags according to the experiment, see http.npf
```

The final command to run is therefore:
```
	cd /local/retina-expe/
	npf-compare "local+fastclick,SAMPLE=pkt_count:Link speed" local+retina:Retina --test http.npf --cluster client=node-0-ctrl,nfs=0 server=node-1-ctrl,nfs=0 dut=node-2-ctrl,nfs=0 --show-full --show-cmd --variables "CPU=1" "SAMPLE={log_tls}" "DPDK_PATH=$DPDK_PATH" "GEN_RATE=[5000-30000#5000]" --graph-filename ssl.pdf --graph-size 6 3 --tags ssl tls rate
```

This will produce a few PDF graphs, the ssl-avg_good_bps.pdf shoud look like the image below. Currently, only the baseline and Retina are tested. We're adding Suricata, stay tuned!

![Figure](figs/ssl-avg_good_bps.png)


