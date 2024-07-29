import time
import requests
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

# Configuration Manager
class ConfigurationManager:
    def __init__(self):
        self.config = {
            "metrics_interval": 10,
            "pushgateway_url": "http://pushgateway:9091"
        }

    def get_config(self, key):
        return self.config.get(key)

# Metrics Collector
class MetricsCollector:
    def __init__(self):
        self.registry = CollectorRegistry()
        self.cpu_usage = Gauge('cpu_usage', 'CPU usage of the node', registry=self.registry)
        self.memory_usage = Gauge('memory_usage', 'Memory usage of the node', registry=self.registry)

    def collect_metrics(self):
        # Placeholder for actual metrics collection logic
        self.cpu_usage.set(50)  # Example data
        self.memory_usage.set(30)  # Example data

        return self.registry

# Data Transmitter
class DataTransmitter:
    def __init__(self, config):
        self.pushgateway_url = config.get_config("pushgateway_url")

    def transmit_data(self, registry):
        push_to_gateway(self.pushgateway_url, job='metrics_collection_agent', registry=registry)

# Agent Controller
class AgentController:
    def __init__(self):
        self.config_manager = ConfigurationManager()
        self.metrics_collector = MetricsCollector()
        self.data_transmitter = DataTransmitter(self.config_manager)
        self.interval = self.config_manager.get_config("metrics_interval")

    def run(self):
        while True:
            metrics = self.metrics_collector.collect_metrics()
            self.data_transmitter.transmit_data(metrics)
            time.sleep(self.interval)

if __name__ == "__main__":
    agent = AgentController()
    agent.run()
