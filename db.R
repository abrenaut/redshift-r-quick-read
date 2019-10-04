##
## Write the result of a Redshift sql query to a dataframe
##

library(RPostgreSQL)
library(uuid)

ReadSqlResults <- function(con, sql.query, aws.access.key, aws.secret.key, s3.bucket, redshift.iam.role) {
  path <- paste0("data/tmp/", UUIDgenerate())

  print("Running SQL query")
  # Escape single quotes in the query
  escaped.sql.query <- gsub("[\r\n]", "", sql.query)
  escaped.sql.query <- gsub("'", "\\\\'", escaped.sql.query)

  # Unload query result to s3
  unload.query <- paste0("UNLOAD ('", escaped.sql.query, "') TO 's3://", s3.bucket, "/", path, "' iam_role '", redshift.iam.role, "' HEADER DELIMITER AS ',' GZIP ALLOWOVERWRITE ADDQUOTES;")
  data <- dbGetQuery(con, unload.query)

  # Download dumps from s3 using aws cli
  cp.cmd <- paste0("AWS_ACCESS_KEY_ID=", aws.access.key, " AWS_SECRET_ACCESS_KEY=", aws.secret.key," aws s3 cp s3://", s3.bucket,"/ . --recursive --exclude '*' --include '", path, "*'")
  system(cp.cmd)

  # Merge the dumps in a single dataframe
  print("Reading csv dumps")
  files <- list.files(path=dirname(path), full.names=TRUE, pattern = paste0(basename(path), ".*.gz"))
  datalist <- lapply(files, function(x){read.csv(file=x, sep = ",", quote = '"', header=TRUE)})

  print("Merging csv dumps in a single dataframe")
  dataset <- do.call(rbind, datalist)
  unlink(files)

  return(dataset)
}
