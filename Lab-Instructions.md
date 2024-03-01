# Azure VNet/Subnet Lab

## Overview

Azure Virtual Networks (VNets) offer a way to logically isolate resources within Azure. Within a VNet, you can segment your resources into subnets, providing further control and security. Setting up a VNet with both a private and a public subnet is a common practice:

- **Private subnet:** This subnet is not directly accessible from the internet. It's ideal for resources that need to communicate with each other within the VNet but don't require public exposure. This enhances security for sensitive data and applications.

- **Public subnet:** This subnet has a public IP address space, allowing resources deployed within it to be accessed directly from the internet. This is suitable for resources like web servers or APIs that need to be publicly available.

By utilizing both private and public subnets within a VNet, you can achieve a balance between security and accessibility for your Azure resources.

To illustrate network connectivity concepts, this lab will walk you through creating a VNet with public and private subnets, and deploying VMs. You'll then explore how resources in these subnets can communicate (or not) with each other.

![Two VMs](images/2-VMs.png)

### Prerequisites

1. Azure account
2. [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed

## Manually Create Resources

1. Create resource group
    1. From the main Azure portal page, click Resource Groups or use the search bar at the top of the screen.
    2. Click `+ Create`
    3. Enter a Resource group name, then click `Review + create`, then `Create`
2. Create VNet
    1. From the search bar, search `Virtual networks` and click the `Virtual networks` result
    2. Click `+ Create` to begin creating an Azure virtual network
        1. This is the *entire* network. We’ll break this down into two subnets in a later step.
    3. Verify your subscription and resource group, then give the network a name.
    4. Click `Next`, leave the checkboxes unchecked on the `Security` tab, then click `Next`
        1. The services on Security are out of scope for this particular lab
    5. On the IP addresses screen, let’s make our overall network a little smaller. Click the dropdown with our CIDR slash (mine defaulted to /16) and update to /26.
        1. Ignore errors for the default subnet -
    6. Delete the default subnet and click `Add a subnet`
        1. In the `Add a subnet` page we’ll first create our public subnet. Enter the following information:
            1. Name: `public-subnet`
            2. Size: /27 (32 addresses)
        2. Leave the rest of the configuration as the default settings and click `Add`
        3. Click `Add a subnet` again, entering the following on the `Add a subnet` page:
            1. Name: `private-subnet`
            2. Size: /27 (32 addresses)
            3. Enable private subnet: check the box
            4. Network security group: `Create new` and name `private-sg` . Click `Ok`.
        4. Leave the rest of the configuration as the default and click “Add”
    7. Once both subnets have been added, click `Review + create` then `Create`. After a few seconds the deployment should complete.  
3. Update `private-sg` to deny all inbound access
    1. Search `Network security groups` and select the search result option
    2. You should see `private-sg` listed. Click the name to open the Overview page.
    3. Under `Settings`, open `Inbound security rules` , then `Add`
    4. Create a security rule with the following information:
        1. Source: `Service Tag`
        2. Source service tag: `VirtualNetwork`
        3. Source port ranges: `*`
        4. Destination: `Any`
        5. Service: `Custom`
        6. Destination port ranges: `*`
        7. Protocol: `Any`
        8. Action: `Deny`
        9. Priority: `1000`
        10. Name: `DenyVnetInbound`
    5. Click `Save`
    6. We have now prevented access to any resource not within `private-subnet`.
4. Create virtual machine in both subnets
    1. Next, create a virtual machine with the following configurations
        1. Basics
            1. Resource group: your resource group name
            2. Virtual machine name: `public-vm`
            3. Image: Ubuntu Server 20.04 LTS
            4. Size: Verify `Standard_B1s` is selected
            5. Administrator Account
                1. Authentication type: SSH public key
                2. Username: `azureuser`
                3. SSH public key source: Generate new key pair
                4. Key pair name: `public-vm-ssh-key`
        2. Networking
            1. Virtual network: your VNet from step 2
            2. Subnet: `public-subnet`
            3. Delete NIC when VM is deleted: check the box (out of scope for the lab)
    2. Click “Review + create”, verify the details, then click “Create”. Be sure to download the private key when the “Generate new key pair” popup appears. Save it in a easily accessible location on your computer. We can delete them after this lab as they will not be useful after deleting our VMs.
    3. Now lets create a virtual machine in our private subnet following similar steps as above with a few changes
        1. Basics
            1. Resource group: your resource group name
            2. Virtual machine name: `private-vm`
            3. Image: Ubuntu Server 20.04 LTS
            4. Size: Verify `Standard_B1s` is selected
            5. Administrator Account
                1. Authentication type: SSH public key
                2. Username: `azureuser`
                3. SSH public key source: Generate new key pair
                4. Key pair name: `private-vm-ssh-key`
        2. Networking
            1. Virtual network: your VNet from step 2
            2. Subnet: `private-subnet`
            3. Public IP: None
            4. Delete NIC when VM is deleted: check the box (out of scope for the lab)
    4. Just like last time, be sure to download your private-vm-ssh-key to the same location as the previous key.

## Use Bicep to Deploy Resources

WIP

## Test Virtual Machine connectivity

1. Attempt SSH into private VM (show you cannot access)
    1. Now that we have everything setup, lets try to connect to our private VM instance.
        1. In the Virtual Machines page, select the `private-vm` instance
        2. On the left hand side, click `Connect`
        3. Select `Native SSH`
        4. Verify you have the correct local machine OS in the top dropdown
            1. Depending on your operating system you will see different instructions
        5. Enter the location on your computer where the `private-vm-ssh-key.pem` file is stored.
        6. Open a terminal (Linux/macOS) or PowerShell (Windows)
        7. Run chmod command if on macos
        8. Paste the SSH command, and paste the SSH command.
        9. After a little bit you should see an error similar to the following:
            1. `ssh: connect to host 10.0.0.36 port 22: Operation timed out`
            2. Add a snippet on why we got this error
2. SSH (or connect some other method) into public VM
    1. Go back to Azure, select  `public-vm`, `Connect`, and use the `Native SSH` option.
    2. Verify the correct local machine OS is checked, enter the folder location of your `public-vm-ssh-key.pem`
    3. Run chmod if on macOS
    4. Paste the SSH command into Terminal (Linux/MacOS) or PowerShell (Windows) and hit enter
    5. When it asks `Are you sure you want to continue connecting?` type `yes` and hit enter.
    6. You should be presented with a `Welcome to Ubuntu 20.04.6 LTS` message, and see `azureuser@public-vm` . Hooray! You’ve connected to the `public-vm` machine!
        1. From here have them ping microsoft.com, google.com, aws.com
        2. `ping -c 3 microsoft.com`
        3. `ping -c 3 google.com`
        4. `ping -c 3 aws.com`
    7. Try to ping `private-vm` , updating the command with the private IP address.
        1. `ping -c 3 <private_ip>`
        2. i.e.: `ping -c 3 10.0.0.36`
    8.
3. Attempt SSH from public VM into private VM
    1. Try to ping `private-vm` , updating the command with the private IP address.
        1. `ping -c 3 <private_ip>`
        2. i.e.: `ping -c 3 10.0.0.36`
4. Update subnet to allow traffic from public subnet
    1. Add new inbound security rule to allow `public-vm` access to `private-vm`
        1. Use private IP of `public-vm` with `/32`
5. Show you can successfully ping from VM in public subnet
    1. Wait a few seconds to allow your new security rule to take effect.
    2. Try to ping `private-vm` , updating the command with the private IP address.
        1. `ping -c 3 <private_ip>`
        2. i.e.: `ping -c 3 10.0.0.36`
6. Attempt SSH again from home network showing you still cannot connect
7. Delete Resource Group
    1. From the Azure home page, click `Resource groups`.
    2. Click the name of your resource group created at the beginning of the lab.
    3. Click `Delete resource group`, check `Apply force delete` checkbox, enter the resource group name for confirmation, and finally `Delete`
    4. All resources should be removed from the subscription and no longer

Provide Bicep (and Terraform?) templates

## Summary

This lab delved into the fundamental concepts of network connectivity within Azure Virtual Networks (VNets). You successfully created a VNet with both public and private subnets, providing a hands-on environment to explore how resources in each subnet interact.

Through this lab, you gained practical experience in:

- **Creating a VNet and Subnets:** You learned how to define an Azure VNet and configure it with separate public and private subnets, understanding the purpose of each subnet in network isolation.
  
- **Deploying Virtual Machines:** You deployed virtual machines (VMs) into both public and private subnets, establishing the foundation for exploring network connectivity.
  
- **Testing Network Connectivity:** You tested communication between VMs in different subnets and with the internet, gaining insights into the default firewall rules and the importance of Network Security Groups (NSGs) for granular control.

By completing this lab, you have gained a solid foundation in understanding how network connectivity works within Azure VNets and the role of subnets in segregating resources for enhanced security and control.
