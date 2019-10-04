Downloading large amount of data from Redshift using RPostgreSQL::dbGetQuery can be pretty slow.

This utility allows to quickly download the result of a Redshift `SELECT` query and create a data frame from it.

Instead of fetching `n` rows at a time from the database, it:

* Unloads the result of the `SELECT` query to compressed csv files on S3
* Downloads the csv files locally using the aws cli
* Reads the csv files and creates a data frame from it

# Requirements

* [aws cli](https://aws.amazon.com/cli/) installed and [configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
* The following R packages: `install.packages('uuid', 'RPostgreSQL')`
* A S3 bucket 
* A AWS role associated to the Redshift cluster with write permission on the bucket
* The AWS access key and secret of a user with read permission on the bucket

# Usage

```r
library(RPostgreSQL)
source("db.R")

drv <- dbDriver("PostgreSQL")
con <- dbConnect(
  drv,
  dbname   = "db_name",
  host     = "host",
  port     = "port",
  user     = "user",
  password = "password"
)

sql.query         <- "SELECT * FROM my_table"
s3.bucket         <- "bucket_name"
redshift.iam.role <- "arn:aws:iam::123456:role/RoleName"
aws.access.key    <- "AWS_ACCESS_KEY_ID"
aws.secret.key    <- "AWS_SECRET_ACCESS_KEY"

df <- ReadSqlResults(con, sql.query, aws.access.key, aws.secret.key, s3.bucket, redshift.iam.role)
head(df)
```