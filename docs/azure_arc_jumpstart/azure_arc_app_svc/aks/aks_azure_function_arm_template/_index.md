---
type: docs
title: "Azure Function ARM Template"
linkTitle: "Azure Function ARM Template"
weight: 2
description: >
---

## Deploy Azure Function application on AKS using an ARM Template

The following README will guide you on how to deploy a "Ready to Go" environment so you can start using [Azure Arc-enabled app services](https://docs.microsoft.com/en-us/azure/app-service/overview-arc-integration) deployed on [Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/intro-kubernetes) cluster using [Azure ARM Template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview).

By the end of this guide, you will have an AKS cluster deployed with an App Service plan, a sample Azure Function application that sends messages to an Azure storage account queue and a Microsoft Windows Server 2019 (Datacenter) Azure VM, installed & pre-configured with all the required tools needed to work with Azure Arc-enabled app services.

> **Note: Currently, Azure Arc-enabled app services is in preview.**

## Prerequisites

* Clone the Azure Arc Jumpstart repository

    ```shell
    git clone https://github.com/microsoft/azure_arc.git
    ```

* [Install or update Azure CLI to version 2.15.0 and above](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest). Use the below command to check your current installed version.

  ```shell
  az --version
  ```

* [Generate SSH Key](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-ssh-keys-detailed) (or use existing ssh key).

* Create Azure service principal (SP)

    To be able to complete the scenario and its related automation, Azure service principal assigned with the “Contributor” role is required. To create it, login to your Azure account run the below command (this can also be done in [Azure Cloud Shell](https://shell.azure.com/).

    ```shell
    az login
    az ad sp create-for-rbac -n "<Unique SP Name>" --role contributor
    ```

    For example:

    ```shell
    az ad sp create-for-rbac -n "http://AzureArcAppSvc" --role contributor
    ```

    Output should look like this:

    ```json
    {
    "appId": "XXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "displayName": "AzureArcAppSvc",
    "name": "http://AzureArcAppSvc",
    "password": "XXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "tenant": "XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    }
    ```

    > **Note: It is optional, but highly recommended, to scope the SP to a specific [Azure subscription](https://docs.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest).**

## Automation Flow

For you to get familiar with the automation and deployment flow, below is an explanation.

* User is editing the ARM template parameters file (1-time edit). These parameters values are being used throughout the deployment.

* Main [_azuredeploy_ ARM template](https://github.com/microsoft/azure_arc/blob/main/azure_arc_app_services_jumpstart/aks/arm_template/azuredeploy.json) will initiate the deployment of the linked ARM templates:

  * [_clientVm_](https://github.com/microsoft/azure_arc/blob/main/azure_arc_app_services_jumpstart/aks/arm_template/clientVm.json) - Deploys the client Windows VM. This is where all user interactions with the environment are made from.
  * [_logAnalytics_](https://github.com/microsoft/azure_arc/blob/main/azure_arc_app_services_jumpstart/aks/arm_template/logAnalytics.json) - Deploys Azure Log Analytics workspace to support Azure Arc-enabled app services logs uploads.

* User remotes into client Windows VM, which automatically kicks off the [_AppServicesLogonScript_](https://github.com/microsoft/azure_arc/blob/main/azure_arc_app_services_jumpstart/aks/arm_template/artifacts/AppServicesLogonScript.ps1) PowerShell script that deploy the AKS cluster and will configure Azure Arc-enabled app services Kubernetes environment on the AKS cluster.

    > **Note: Notice the AKS cluster will be deployed via the PowerShell script automation.**

## Deployment

As mentioned, this deployment will leverage ARM templates. You will deploy a single template that will initiate the entire automation for this scenario.

* The deployment is using the ARM template parameters file. Before initiating the deployment, edit the [_azuredeploy.parameters.json_](https://github.com/microsoft/azure_arc/blob/main/azure_arc_app_services_jumpstart/aks/arm_template/azuredeploy.parameters.json) file located in your local cloned repository folder. An example parameters file is located [here](https://github.com/microsoft/azure_arc/blob/main/azure_arc_app_services_jumpstart/aks/arm_template/artifacts/azuredeploy.parameters.example.json).

  * _`sshRSAPublicKey`_ - Your SSH public key
  * _`spnClientId`_ - Your Azure service principal id
  * _`spnClientSecret`_ - Your Azure service principal secret
  * _`spnTenantId`_ - Your Azure tenant id
  * _`windowsAdminUsername`_ - Client Windows VM Administrator name
  * _`windowsAdminPassword`_ - Client Windows VM Password. Password must have 3 of the following: 1 lower case character, 1 upper case character, 1 number, and 1 special character. The value must be between 12 and 123 characters long.
  * _`myIpAddress`_ - Your local public IP address. This is used to allow remote RDP and SSH connections to the client Windows VM and AKS cluster.
  * _`logAnalyticsWorkspaceName`_ - Unique name for the deployment log analytics workspace.
  * _`kubernetesVersion`_ - AKS version
  * _`dnsPrefix`_ - AKS unique DNS prefix
  * _`deployAppService`_ - Boolean that sets whether or not to deploy App Service plan and a Web App. For this scenario, we leave it set to _**false**_.
  * _`deployFunction`_ - Boolean that sets whether or not to deploy App Service plan and an Azure Function application. For this scenario, we leave it set to _**true**_.
  * _`deployLogicApp`_ - Boolean that sets whether or not to deploy App Service plan and an Azure Logic App. For this scenario, we leave it set to _**false**_.
  * _`templateBaseUrl`_ - GitHub URL to the deployment template - filled in by default to point to [Microsoft/Azure Arc](https://github.com/microsoft/azure_arc) repository, but you can point this to your forked repo as well.

* To deploy the ARM template, navigate to the local cloned [deployment folder](https://github.com/microsoft/azure_arc/tree/main/azure_arc_app_services_jumpstart/aks/arm_template) and run the below command:

    ```shell
    az group create --name <Name of the Azure resource group> --location <Azure Region>
    az deployment group create \
    --resource-group <Name of the Azure resource group> \
    --name <The name of this deployment> \
    --template-uri https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_app_services_jumpstart/aks/arm_template/azuredeploy.json \
    --parameters <The *azuredeploy.parameters.json* parameters file location>
    ```

    > **Note: Make sure that you are using the same Azure resource group name as the one you've just used in the `azuredeploy.parameters.json` file**

    For example:

    ```shell
    az group create --name Arc-Data-Demo --location "East US"
    az deployment group create \
    --resource-group Arc-AppSvc-Demo \
    --name arcappsvc \
    --template-uri https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_app_services_jumpstart/aks/arm_template/azuredeploy.json \
    --parameters azuredeploy.parameters.json
    ```

    > **Note: The deployment time for this scenario can take ~5-10min**

    > **Note: Since Azure Arc-enabled app services is currently in preview, deployment regions availability is limited to East US and West Europe.**

* Once Azure resources has been provisioned, you will be able to see it in Azure portal. At this point, the resource group should have **7 various Azure resources** deployed.

    ![ARM template deployment completed](./01.png)

    ![New Azure resource group with all resources](./02.png)

## Windows Login & Post Deployment

* Now that first phase of the automation is completed, it is time to RDP to the client VM using it's public IP.

    ![Client VM public IP](./03.png)

* At first login, as mentioned in the "Automation Flow" section above, the [_AppServicesLogonScript_](https://github.com/microsoft/azure_arc/blob/main/azure_arc_app_services_jumpstart/aks/arm_template/artifacts/AppServicesLogonScript.ps1) PowerShell logon script will start it's run.

* Let the script to run its course and **do not close** the PowerShell session, this will be done for you once completed. Once the script will finish it's run, the logon script PowerShell session will be closed, the Windows wallpaper will change and the Azure Function application will be deployed on the cluster and be ready to use.

    > **Note: As you will notices from the screenshots below, during the Azure Arc-enabled app services environment, the _log-processor_ service pods will be restarted and will go trough multiple Kubernetes pod lifecycle stages. This is normal and can safely be ignored. To learn more about the various Azure Arc-enabled app services Kubernetes components, visit the official [Azure Docs page](https://docs.microsoft.com/en-us/azure/app-service/overview-arc-integration#pods-created-by-the-app-service-extension).**

    ![PowerShell logon script run](./04.png)

    ![PowerShell logon script run](./05.png)

    ![PowerShell logon script run](./06.png)

    ![PowerShell logon script run](./07.png)

    ![PowerShell logon script run](./08.png)

    ![PowerShell logon script run](./09.png)

    ![PowerShell logon script run](./10.png)

    ![PowerShell logon script run](./11.png)

    ![PowerShell logon script run](./12.png)

    ![PowerShell logon script run](./13.png)

    ![PowerShell logon script run](./14.png)

    ![PowerShell logon script run](./15.png)

    ![PowerShell logon script run](./16.png)

    ![PowerShell logon script run](./17.png)

    ![PowerShell logon script run](./18.png)

    ![PowerShell logon script run](./19.png)

    ![PowerShell logon script run](./20.png)

    ![PowerShell logon script run](./21.png)

    ![PowerShell logon script run](./22.png)

    ![PowerShell logon script run](./23.png)

    ![PowerShell logon script run](./24.png)

  Once the script finishes it's run, the logon script PowerShell session will be closed, the Windows wallpaper will change, and both the app service plan and the Azure Function application deployed on the cluster will be ready.

    ![Wallpaper change](./25.png)

* Since this scenario is deploying both the app service plan and a sample Azure Function application, you will also notice additional, newly deployed Azure resources in the resources group (at this point you should have **15 various Azure resources deployed**. The important ones to notice are:

  * **Azure Arc-enabled Kubernetes cluster** - Azure Arc-enabled app services are using this resource to deploy the app services [cluster extension](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/conceptual-extensions), as well as using Azure Arc [Custom locations](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/conceptual-custom-locations).

  * **Custom location** - Provides a way for tenant administrators to use their Azure Arc-enabled Kubernetes clusters as a target location for deploying Azure services.

  * [**App Service Kubernetes Environment**](https://docs.microsoft.com/en-us/azure/app-service/overview-arc-integration#app-service-kubernetes-environment) - The App Service Kubernetes environment resource is required before apps may be created. It enables configuration common to apps in the custom location, such as the default DNS suffix.

  * [**App Service plan**](https://docs.microsoft.com/en-us/azure/app-service/overview-hosting-plans) - In App Service (Web Apps, API Apps, or Mobile Apps), an app always runs in an App Service plan. In addition, Azure Functions also has the option of running in an App Service plan. An App Service plan defines a set of compute resources for an Azure Function to run.

  * [**Azure Function**](https://docs.microsoft.com/en-us/azure/azure-functions/functions-overview) - Azure Functions is a serverless solution that allows you to write less code, maintain less infrastructure, and save on costs.

  * [Application Insights](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview) - Application Insights, a feature of Azure Monitor, is an extensible Application Performance Management (APM) service for developers and DevOps professionals. Use it to monitor your live applications.

  * Azure Storage Account - The storage account deployed in this scenario is used for hosting the [queue storage](https://docs.microsoft.com/en-us/azure/storage/queues/storage-queues-introduction) where the Azure Function will be sending messages to that can be leveraged later in an application event-driven architecture.

  ![Additional Azure resources in the resource group](./26.png)

* In this scenario, **a sample Jumpstart Azure Function application** was deployed. To open the deployed Function application in your web browser, simply click the Azure Function resource and the created URL.

  ![Azure Function URL](./27.png)

  ![Azure Function open in a web browser](./28.png)

* To demonstrate the messaging queuing element and to show how messages are stored in the queue storage, the Azure Function deployment script also generates 10 sample messages. To view it, click on the newly created storage account and go to the "Queues" section where you will see the new queue and the stored messages.

  ![Azure Storage Account](./29.png)

  ![Azure storage queue](./30.png)

  ![Azure Function messages in storage queue](./31.png)

* Alternatively, you can view the same queue storage using the Azure Storage Explorer client application installed automatically in the Client VM or using the Azure Storage Explorer portal-based view.

  ![Azure Storage Explorer client application storage queue](./32.png)

  ![Azure Storage Explorer portal-based view](./33.png)

  ![Azure Storage Explorer portal-based view storage queue](./34.png)

* To generate your own messages using the Function application, use the Function invoke URL. As part of the deployment script, a _`funcUrl.txt`_ text file located in the Client VM under _C:\Temp_ folder that includes invoke URL was created for you. Copy the URL and open it in your web browser while adding the message text to it using the _`?name=<Something>`_ syntax, for example, _`?name=Bilbo`_.

  ![funcUrl.txt file](./35.png)

  ![Invoke URL](./36.png)

  ![Invoke URL in web browser](./37.png)

* Go back to the storage queue and see the new added message.

  ![New message in storage queue](./38.png)

* As part of the deployment, an Application Insights instance was also provisioned to provide you with relevant performance and application telemetry.

  ![Application Insights instance](./39.png)

## Cluster extensions

In this scenario, the Azure Arc-enabled app services cluster extension was deployed and used throughout this scenario in order to deploy the app services infrastructure.

* In order to view cluster extensions, click on the Azure Arc-enabled Kubernetes resource Extensions settings.

  ![Azure Arc-enabled Kubernetes resource](./40.png)

  ![Azure Arc-enabled Kubernetes cluster extensions settings](./41.png)

## Cleanup

* If you want to delete the entire environment, simply delete the deployed resource group from the Azure portal.

  ![Delete Azure resource group](./42.png)
