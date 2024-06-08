# Description
## Use jenkins slave to automate deployment of openshift , first build and push docker image then deploy on openshift cluster using token credentials optained from service account

### Step 1: Create ServiceAccount and give it role then extract the token

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/f4ae149d-8594-4b7a-b0ea-6e233efea6e5" width="1000" > 

### Step 2: Create Deployment and Service yaml files

#### Deploymentfile

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/84b6f566-8608-471b-b801-68e881b1d315" width="1000" > 

#### Servicefile

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/5b1ecad2-7fd2-46eb-ad65-1c573042e945" width="1000" > 

### Step 3: Create Dockerfile to build the image

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/4c900e90-8df7-4a8f-84f2-158bba6cee74" width="1000" > 

### Step 4: Create Jenkinsfile 

#### *using Shared Library:
```groovy
@Library('shared-library')_
```

#### *using the jenkins-slave agent
```groovy
    agent { 
        // Specifies a label to select an available agent
         node { 
             label 'jenkins-slave'
         }
    }
```

#### *using 3 Stages(Build, Push, Deploy):
```groovy
     stages {
        stage('Build Docker Image') {
            steps {
                script {
                	// Navigate to the directory contains Dockerfile
                 		buildDockerImage("${imageName}")
                }
            }
        }
        stage('push Docker Image') {
            steps {
                script {
                	// Navigate to the directory contains Dockerfile
                 		pushDockerImage("${dockerHubCredentialsID}", "${imageName}")
                }
            }
        }


        stage('Deploy on OpenShift Cluster') {
            steps {
                script { 
				deployToOpenShift("${openshiftCredentialsID}", "${openshiftClusterURL}", "${openshiftProject}", "${imageName}")
                }
            }
        }
    }
```

#### *using Post to show the result of the process
```bash
    post {
        success {
            echo "${JOB_NAME}-${BUILD_NUMBER} pipeline succeeded"
        }
        failure {
            echo "${JOB_NAME}-${BUILD_NUMBER} pipeline failed"
        }
    }
}
```

### Step 5: Create Shared Library

#### *buildDockerImage.groovy
```
#!usr/bin/env groovy
def call(String imageName) {

        // Build and push Docker image
        echo "Building Docker image..."
        sh "docker build -t ${imageName}:v1 ."
}
```

#### *pushDockerImage.groovy
```
#!usr/bin/env groovy
def call(String dockerHubCredentialsID, String imageName) {

	// Log in to DockerHub 
	withCredentials([usernamePassword(credentialsId: "${dockerHubCredentialsID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
		sh "docker login -u ${USERNAME} -p ${PASSWORD}"
        }
        
        // Build and push Docker image
        echo "Pushing Docker image..."
        sh "docker push ${imageName}:v1"	 
}
```

#### *deployToOpenShift.groovy
```
#!/usr/bin/env groovy

//OpenShiftCredentialsID can be credentials of service account token or KubeConfig file 
def call(String OpenShiftCredentialsID, String openshiftClusterurl, String openshiftProject, String imageName) {
    
    // login to OpenShift Cluster via cluster url & service account token
    withCredentials([string(credentialsId: "${OpenShiftCredentialsID}", variable: 'OpenShift_CREDENTIALS')]) {
            sh "oc login --server=${openshiftClusterurl} --token=${OpenShift_CREDENTIALS} --insecure-skip-tls-verify"
            sh "oc apply -f deployment.yml"
            sh "oc apply -f service.yml"
    }
}
```

[This is the repo of the Shared Library](https://github.com/saeedkouta/jenkins-oc-shared-library.git)


### Step 6: Create Jenkins-Matser

#### Iam Using As docker Container As Jenkins-Master and this is it's Configration
```
sudo docker run -p 8080:8080 -p 50000:50000 -d \
 -v jenkins_home:/var/jenkins_home \
 -v /var/run/docker.sock:/var/run/docker.sock \
 -v $(which docker):/usr/bin/docker jenkins/jenkins 
```

### Step 7 : Configure the shared library on the jenkins system

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/f29eec84-3913-4ceb-b89c-101d3145bf6a" width="1000" > 

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/16af7cea-c0e3-4a47-84f3-079de3a9168f" width="1000" > 

### Step 8: Add Credentials  

#### *OC-Token:

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/9f2f5cbe-c92e-43da-bba4-541736828114" width="1000" > 

#### *GitHub:

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/4115c0f2-3f66-423b-876b-e673b16623e5" width="1000" > 

#### *DockerHub

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/a7539510-6676-4a49-af22-e948cde9918e" width="1000" > 

### Step 9: Create Jenkins-slave agent

#### *Iam using Ec2-instance As Jenkins-Slave:

#### 1- Create The instance :

##### *Using Ubuntu machine

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/3372b56e-6ab4-46b4-a2d5-254bf756e213" width="1000" > 

##### *Create A Key-pair

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/84f50f44-1c13-4bb4-aead-42fb356f44e6" width="1000" > 

##### *Allow SSH

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/940275c9-4e5d-49fd-b8b3-923dfa085396" width="1000" > 

#### 2- Use Ansible Roles to Install the Required Packages

##### *Role to Install Java:

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/d10a2558-1fc8-4651-a0c5-23dce7efa3af" width="1000" > 

##### *Role to Install Docker:

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/f62981f7-c4db-4cae-a24c-a93335cd8e47" width="1000" > 

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/2a9f7c9b-b8d3-4b13-b9ea-f986ffff65a8" width="1000" > 

##### *Role to Install OC:

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/b1730000-abef-4adf-aec9-15040fa5a90d" width="1000" > 

##### *The Run of The playbook:

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/860388e6-a7e3-46c7-b73d-128931ad09b1" width="1000" > 

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/6ecfc8b8-b8f0-4bd7-a211-ac123bda83ac" width="1000" > 

### Step 10: Create The Jenkins-slave Node

##### *Connect to The Ec2 Using SSH once to add The master as knowing host

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/4b29381e-227d-4b70-8324-3bed0db79789" width="1000" > 

##### *Add The Root Dir of the Ec2

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/92e7e520-5b8c-43f3-9763-fe4c045ba6d0" width="1000" > 

##### *Add The public ip of the Ec2 and Create Credentials with it's Key

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/aea39ae1-5c87-498e-8edb-0e8e2d25c54a" width="1000" > 

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/9b11ad8c-258c-46ba-b0bb-0aaaf717e9f3" width="1000" > 

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/70a8c5e7-278c-451d-92dd-d047d8f6c2ac" width="1000" > 

##### *Go to Logs to Ensure that the Connection is successfully done

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/5b35c167-6896-439a-87dd-31e226898462" width="1000" > 

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/c33f7391-ffb9-40c8-b9a7-2c619845d3e5" width="1000" > 

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/8b2be18b-5495-41bc-b623-f10b5bb3b176" width="1000" > 

### Step 11: Create The Pipeline 

#### 1- Create a Pipeline and add the repo of the project on it:

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/db2e774e-b059-4976-8706-b2e359ca180d" width="1000" > 

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/1ff836b7-565e-4e8e-a971-ce1c52ab4e26" width="1000" > 

#### 2- Build The Pipeline:

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/cc9195d0-db5f-4846-8562-35a41dbfbf1b" width="1000" > 

#### 3- Ensure That the image pushed to DockerHub

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/ca47e367-8797-4cf5-9a7a-d6b598f80ec5" width="1000" > 

### Step 12: Ensure That the Deploy is Created And use port-forward to see The Website

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/bd2d8f20-5f94-4939-a440-0f8b2fc03e32" width="1000" > 

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/bdd2ac1a-fb70-481b-92e6-a9552c28e03a" width="1000" > 








