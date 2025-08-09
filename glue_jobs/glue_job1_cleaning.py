import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# 读取原始 CSV 数据
datasource = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    format="csv",
    connection_options={"paths": ["s3://sensor-pipeline-tony-2025/raw-data/"]},
    format_options={"withHeader": True}
)

# 简单清洗：移除空值
cleaned = DropNullFields.apply(frame=datasource)

# 保存为 parquet 到 cleaned-data 路径
glueContext.write_dynamic_frame.from_options(
    frame=cleaned,
    connection_type="s3",
    format="parquet",
    connection_options={"path": "s3://sensor-pipeline-tony-2025/cleaned-data/"}
)

job.commit()
