from sagemaker import image_uris

container = image_uris.retrieve(
    framework='xgboost',
    region='us-east-1',
    version='1.5-1'  # 或你希望的版本
)
print(container)
