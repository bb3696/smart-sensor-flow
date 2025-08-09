import pandas as pd
import numpy as np
import os
import xgboost as xgb

# SageMaker will inject these environment variables
prefix = os.environ.get("SM_CHANNEL_TRAIN", "/opt/ml/input/data/train")
model_dir = os.environ.get("SM_MODEL_DIR", "/opt/ml/model")

# Load training data
df = pd.read_parquet(os.path.join(prefix, "aggregated.parquet"))

# Feature engineering
df['timestamp'] = pd.to_datetime(df['window_start'])
df['hour'] = df['timestamp'].dt.hour
df['minute'] = df['timestamp'].dt.minute

X = df[['hour', 'minute']]
y = df['avg_temperature']

dtrain = xgb.DMatrix(X, label=y)

# Train model
params = {"objective": "reg:squarederror"}
model = xgb.train(params, dtrain, num_boost_round=10)

# Save model to expected path
model.save_model(os.path.join(model_dir, "xgboost-model.json"))
