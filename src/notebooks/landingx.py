# src/00_setup_and_generate_data.py
# This script creates the initial landing zone and populates it with sample data.

import random
from datetime import datetime, timezone, timedelta
from pyspark.sql import SparkSession

def generate_data(spark, stream_type, advertiser_count):
    """Generates a single batch of sample data."""
    # now = datetime.now(timezone.utc)
    data = []
    
    for _ in range(advertiser_count * 2): # Generate 2 events per advertiser
        advertiser_id = random.randint(1, advertiser_count)
        moment = datetime.now().strftime("%H:%M")
        
        if stream_type == 'paid_event':
            record = {
                "advertiser_id": advertiser_id,
                "moment": moment,
                "amount": round(random.uniform(1.00, 1.40), 2)
            }
        elif stream_type == 'budget_change':
            record = {
                "advertiser_id": advertiser_id,
                "moment": moment,
                "new_budget_value": round(random.uniform(10.00, 30.00), 2)
            }
        data.append(record)
        
    return spark.createDataFrame(data)

def main():
    spark = SparkSession.builder.appName("Setup_and_Generate_Data").getOrCreate()
    
    catalog_name = "ad_monitor"
    schema_name = "landing"
    
    # --- 1. Setup Infrastructure ---
    print(f"Creating schema '{catalog_name}.{schema_name}' if it does not exist...")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {catalog_name}.{schema_name}")
    
    paid_events_volume_path = f"/Volumes/{catalog_name}/{schema_name}/paid_events_stream"
    budget_changes_volume_path = f"/Volumes/{catalog_name}/{schema_name}/budget_changes_stream"
    
    print(f"Creating volume at {paid_events_volume_path} if it does not exist...")
    spark.sql(f"CREATE VOLUME IF NOT EXISTS {catalog_name}.{schema_name}.paid_events_stream")
    
    print(f"Creating volume at {budget_changes_volume_path} if it does not exist...")
    spark.sql(f"CREATE VOLUME IF NOT EXISTS {catalog_name}.{schema_name}.budget_changes_stream")
    
    # --- 2. Generate and Write Data ---
    print("Generating sample paid events data...")
    paid_events_df = generate_data(spark, 'paid_event', advertiser_count=10)
    paid_events_df.write.format("delta").mode("append").save(paid_events_volume_path)
    print(f"Successfully wrote {paid_events_df.count()} records to paid_events_stream.")

    print("Generating sample budget changes data...")
    budget_changes_df = generate_data(spark, 'budget_change', advertiser_count=10)
    budget_changes_df.write.format("delta").mode("append").save(budget_changes_volume_path)
    print(f"Successfully wrote {budget_changes_df.count()} records to budget_changes_stream.")
    
    print("✅ Data generation and infrastructure setup complete.")

if __name__ == "__main__":
    main()
