# Initial checks of the validity of the data
library(wmf)
library(readr)
library(jsonlite)

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
                           '/wmf/data/raw/eventlogging/eventlogging_WikipediaPortal';
                         ALTER TABLE ABTestPortalData
                         ADD PARTITION (year=2016, month=1, day=13, hour=20)
                         LOCATION '/wmf/data/raw/eventlogging/eventlogging_WikipediaPortal/hourly/2016/01/13/20';
                         SELECT get_json_object(json_string, '$.event.cohort') as cohort,
                                get_json_object(json_string, '$.event.session_id') as session_id,
                                get_json_object(json_string, '$.event.event_type') as event_type,
                                get_json_object(json_string, '$.event.section_used') as section_used
                        FROM ABTestPortalData WHERE hour = 20;")
data <- data[!data$session_id == "",]

# Simple tests
stopifnot(length(unique(data$cohort)) == 4)
stopifnot(length(unique(data$section_used)) == 6)

# Awkward visual inspections
table(data$cohort, data$event_type)
table(data$cohort, data$section_used)
data <- as.data.table(data)
sessions <- data[,length(unique(session_id)), by = "cohort"]
sessions$V1/sum(sessions$V1)
