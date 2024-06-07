# Description
## Use jenkins slave to automate deployment of openshift , first build and push docker image then deploy on openshift cluster using token credentials optained from service account

### Step 1: Create ServiceAccount and give it role then extract the token

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/f4ae149d-8594-4b7a-b0ea-6e233efea6e5" width="1000" > 

### Step 2: Create Dockerfile to build the image

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/4c900e90-8df7-4a8f-84f2-158bba6cee74" width="1000" > 

### Step 3: Create Jenkinsfile 

#### *using Shared Library:
```
@Library('shared-library')_
```

#### *using the jenkins-slave agent
```
    agent { 
        // Specifies a label to select an available agent
         node { 
             label 'jenkins-slave'
         }
    }
```

### *using 3 Stages(Build, Push, Deploy):
```
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
```
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

### Step 4: Create Shared Library

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
    
    // Update deployment.yaml with new Docker Hub image
    sh "sed -i 's|image:.*|image: ${imageName}:v1|g' deployment.yml"

    // login to OpenShift Cluster via cluster url & service account token
    withCredentials([string(credentialsId: "${OpenShiftCredentialsID}", variable: 'OpenShift_CREDENTIALS')]) {
            sh "oc login --server=${openshiftClusterurl} --token=${OpenShift_CREDENTIALS} --insecure-skip-tls-verify"
            sh "oc apply -f deployment.yml"
            sh "oc apply -f service.yml"
    }
}
```

[This is the repo of the Shared Library](https://github.com/saeedkouta/jenkins-oc-shared-library.git)


### Step 5: Create Jenkins-Matser

#### Iam Using As docker Container As Jenkins-Master and this is it's Configration
```
sudo docker run -p 8080:8080 -p 50000:50000 -d \
 -v jenkins_home:/var/jenkins_home \
 -v /var/run/docker.sock:/var/run/docker.sock \
 -v $(which docker):/usr/bin/docker jenkins/jenkins 
```

### Step 6 : Configure the shared library on the jenkins system

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/f29eec84-3913-4ceb-b89c-101d3145bf6a" width="1000" > 

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/16af7cea-c0e3-4a47-84f3-079de3a9168f" width="1000" > 

### Step 7: Add Credentials  

#### * OC-Token

<img src="https://github.com/saeedkouta/Jenkins-OC-Project/assets/167209058/9f2f5cbe-c92e-43da-bba4-541736828114" width="1000" > 









