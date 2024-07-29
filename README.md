## Kubernetes Monitoring Agent

#### Overview
This repository contains the code and resources for the Kubernetes Monitoring Agent, a key component of our framework for enhancing Kubernetes security through real-time anomaly detection and feedback-driven machine learning models. The Monitoring Agent collects metrics from both applications and nodes within a Kubernetes environment and sends this data to both a Model Agent and a central database for further analysis and training.

##### Key Features
- Comprehensive Metrics Collection: Gathers metrics from both application and node levels.
- Real-Time Data Transmission: Sends collected metrics to the Model Agent and central database in real-time.
- Scalability: Designed to handle large-scale Kubernetes environments.

##### Setup and Installation
1. Navigate to the monitoring_agent directory:
`cd monitoring_agent`

2. Install the required Python packages:
`pip install -r requirements.txt`

3. Run the Monitoring Agent:
`python agent.py`

##### Docker Setup
1. Build the Docker image:
`docker build -t monitoring_agent .
`
2. Run the Docker container:
`docker run -p 5000:5000 monitoring_agent
`
##### Kubernetes Deployment
1. Navigate to the kubernetes directory:
`cd kubernetes
`
2. Apply the Monitoring Agent deployment:
`kubectl apply -f monitoring_agent_deployment.yaml
`
#### Usage
- Metrics Collection: The Monitoring Agent continuously collects metrics from Kubernetes nodes and applications, sending them to the Model Agent and central database for real-time anomaly detection and model training.