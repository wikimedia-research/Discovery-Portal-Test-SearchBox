# Initial checks of the validity of the data


main <- function(){
  
  # Retrieve a sample of the data. Analytics-store is backlogged, oh joy,
  # so HDFS it is.
  data <- wmf::hive_query("ADD JAR file:///usr/lib/hive-hcatalog/share/hcatalog/hive-hcatalog-core.jar;
                           USE ironholds;
                           CREATE EXTERNAL TABLE `ABTestPortalData` (
                             `json_string` string
                           )
                           PARTITIONED BY (
                             year int,
                             month int,
                             day int,
                             hour int
                           )
                           STORED AS INPUTFORMAT
                             'org.apache.hadoop.mapred.SequenceFileInputFormat'
                           OUTPUTFORMAT
                             'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
                           LOCATION 
                             '/wmf/data/raw/eventlogging/eventlogging_eventlogging_WikipediaPortal';
                           ALTER TABLE ABTestPortalData
                           ADD PARTITION (year=2016, month=1, day=13, hour=10)
                           LOCATION '/wmf/data/raw/eventlogging/eventlogging_eventlogging_WikipediaPortal/hourly/2016/01/13/10';")
                            
-- Add a partition
ALTER TABLE CentralNoticeBannerHistory
ADD PARTITION (year=2015, month=9, day=17, hour=16)
LOCATION '/wmf/data/raw/eventlogging/eventlogging_CentralNoticeBannerHistory/hourly/2015/09/17/16';")
}