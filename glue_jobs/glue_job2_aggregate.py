import sys
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, window, avg, hour, dayofweek
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Step 1: 读取清洗后的数据
df = spark.read.parquet("s3://sensor-pipeline-tony-2025/cleaned-data/")

# Step 2: 转换时间戳为 Spark timestamp 类型
df = df.withColumn("timestamp", col("timestamp").cast("timestamp"))

# Step 3: 执行 5 分钟窗口聚合
agg_df = df.groupBy(
    window(col("timestamp"), "5 minutes")
).agg(
    avg("temperature").alias("avg_temperature"),
    avg("humidity").alias("avg_humidity")
)

# Step 4: 展平 window，并保留 window_start
flattened = agg_df.select(
    col("window.start").alias("window_start"),
    col("window.end").alias("window_end"),
    "avg_temperature",
    "avg_humidity"
)

# Step 5: 添加时间戳衍生特征
enriched = flattened \
    .withColumn("hour", hour(col("window_start"))) \
    .withColumn("dayofweek", dayofweek(col("window_start"))) \
    .withColumn("is_weekend", (col("dayofweek") >= 6).cast("int"))

# Step 6: 保存原始分析文件（含 timestamp）
flattened.write.mode("overwrite").parquet("s3://sensor-pipeline-tony-2025/aggregated-data/")

# Step 7: 保存训练文件（只保留 float）
enriched.select(
    col("avg_temperature").alias("label"),
    col("avg_humidity"),
    col("hour").cast("float"),
    col("dayofweek").cast("float"),
    col("is_weekend").cast("float")
).write.mode("overwrite").parquet("s3://sensor-pipeline-tony-2025/for-training/")

job.commit()
