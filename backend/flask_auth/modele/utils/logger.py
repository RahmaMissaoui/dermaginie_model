# utils/logger.py
import logging
import sys
from datetime import datetime


def setup_logger(name='skin_lesion_detection', log_file=None):
    """Setup logger with console and file handlers."""
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)
    console_format = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    console_handler.setFormatter(console_format)
    logger.addHandler(console_handler)
    
    # File handler
    if log_file is None:
        log_file = f'logs/training_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'
    
    file_handler = logging.FileHandler(log_file)
    file_handler.setLevel(logging.INFO)
    file_format = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    file_handler.setFormatter(file_format)
    logger.addHandler(file_handler)
    
    return logger


def log_metrics(logger, metrics, phase='train', epoch=None):
    """Log metrics to logger."""
    if epoch is not None:
        logger.info(f"Epoch {epoch} - {phase.upper()}")
    
    for key, value in metrics.items():
        logger.info(f"  {key}: {value:.4f}")