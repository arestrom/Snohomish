#===========================================================================
# Add new streams to SG...Several indicated where points exist but no stream
# geometry...either for point or for downstream portion. I want all the
# streams to link up to saltwater in some way. No orphan segments.
#
# Notes:
#  1.
#
#  Completed: 2020-10-28
#
# AS 2020-10-28
#===========================================================================

# Clear workspace
rm(list = ls(all.names = TRUE))

# Load libraries
library(DBI)
library(RPostgres)
library(dplyr)
library(remisc)
library(tidyr)
library(sf)
library(stringi)
library(lubridate)
library(glue)
library(iformr)
library(odbc)

# Set options
options(digits=14)

# Keep connections pane from opening
options("connectionObserver" = NULL)

#=====================================================================================
# Function to get user for database
pg_user <- function(user_label) {
  Sys.getenv(user_label)
}

# Function to get pw for database
pg_pw <- function(pwd_label) {
  Sys.getenv(pwd_label)
}

# Function to get pw for database
pg_host <- function(host_label) {
  Sys.getenv(host_label)
}

# Function to connect to postgres on local
pg_con_local = function(dbname, port = '5432') {
  con <- dbConnect(
    RPostgres::Postgres(),
    host = "localhost",
    dbname = dbname,
    user = pg_user("pg_user"),
    password = pg_pw("pg_pwd_local"),
    port = port)
  con
}

# Function to connect to postgres on prod
pg_con_prod = function(dbname, port = '5432') {
  con <- dbConnect(
    RPostgres::Postgres(),
    host = pg_host("pg_host_prod"),
    dbname = dbname,
    user = pg_user("pg_user"),
    password = pg_pw("pg_pwd_prod"),
    port = port)
  con
}

#=========================================================================
# Import all stream data from sg for WRIAs 22 and 23
#=========================================================================

# Define query to get needed data
qry = glue("select distinct wb.waterbody_id, wb.waterbody_name, wb.waterbody_display_name, ",
           "wb.latitude_longitude_id as llid, wb.stream_catalog_code as cat_code, ",
           "st.stream_id, st.gid, st.geom as geometry ",
           "from waterbody_lut as wb ",
           "left join stream as st on wb.waterbody_id = st.waterbody_id ",
           "left join location as loc on wb.waterbody_id = loc.waterbody_id ",
           "left join wria_lut as wr on loc.wria_id = wr.wria_id ",
           "where wria_code in ('05', '07') ",
           "order by waterbody_name")

# Get values from source
db_con = pg_con_local(dbname = "spawning_ground")
streams_st = st_read(db_con, query = qry)
dbDisconnect(db_con)

# Pull out cases where LLID is duplicated....None anymore, only streams with missing LLIDs
dup_stream_id = streams_st %>%
  st_drop_geometry() %>%
  group_by(llid) %>%
  mutate(n_seq = row_number()) %>%
  ungroup() %>%
  filter(n_seq > 1) %>%
  select(llid) %>%
  distinct()

# Pull out cases with missing LLIDs
no_llid = streams_st %>%
  st_drop_geometry() %>%
  filter(is.na(llid)) %>%
  distinct()

# Identify any streams where LLID needs to be updated
update_llid = no_llid %>%
  filter(!is.na(stream_id))

# Arrange streams
streams_st = streams_st %>%
  arrange(waterbody_name)

#=========================================================================
# Update missing LLID to all DBs....inspect in QGIS to find LLID.
#=========================================================================
# # Define query
# qry = glue("update waterbody_lut ",
#            "set latitude_longitude_id = '1234654469839' ",
#            "where waterbody_id = '17557462-e4d9-4497-ba26-b54ad9831413'")
#
# # Update local
# db_con = pg_con_local(dbname = "spawning_ground")
# DBI::dbExecute(db_con, qry)
# dbDisconnect(db_con)
#
# # Define query
# qry = glue("update spawning_ground.waterbody_lut ",
#            "set latitude_longitude_id = '1234654469839' ",
#            "where waterbody_id = '17557462-e4d9-4497-ba26-b54ad9831413'")
#
# # Update FISH prod
# db_con = pg_con_prod(dbname = "FISH")
# DBI::dbExecute(db_con, qry)
# dbDisconnect(db_con)

#=========================================================================
# Get stream data from Leslie's latest
#=========================================================================

# # Define query to get wria_data for join
# qry = glue("select * from wria_lut")
#
# # Get values from source
# db_con = pg_con_local(dbname = "spawning_ground")
# wria_st = st_read(db_con, query = qry)
# dbDisconnect(db_con)
#
#
# # Get Leslies latest gdb...as of 2020-03-12
# # Exported as gpkg in QGIS since code below failed
# # cat_llid_st = read_sf("data/wdfwStreamCatalogGeometry.gdb", layer = "StreamCatalogLine", crs = 2927)
# cat_llid = read_sf("data/StreamCatalogLine.gpkg", layer = "StreamCatalogLine", crs = 2927)
# st_crs(cat_llid)$epsg
# # Write chehalis subset to local
# cat_llid_kelly = cat_llid %>%
#   st_zm() %>%
#   st_join(wria_st) %>%
#   filter(wria_code %in% c("05", "07"))
# # Pull out what I need
# cat_llid_kelly = cat_llid_kelly %>%
#   select(cat_code = StreamCatalogID, cat_name = StreamCatalogName, llid = LLID,
#          llid_name = LLIDName, comment = Comment, orientation = OrientID)
# write_sf(cat_llid_kelly, "data/cat_llid_kelly_2020-03-12.gpkg")
# Get Lestie's latest llid data
cat_llid_kelly= read_sf("data/cat_llid_kelly_2020-03-12.gpkg",
                        layer = "cat_llid_kelly_2020-03-12", crs = 2927)

#=========================================================================
# Get stream data from Arleta's latest
#=========================================================================

# # Get Arleta's latest llid data....see notes above....but this time from a gdb
# llid_st = read_sf("data/LLID20200311.gdb", layer = "LLID_routes", crs = 2927)
# # Write chehalis subset to local
# llid_kelly = llid_st %>%
#   st_zm() %>%
#   st_join(wria_st) %>%
#   filter(wria_code %in% c("05", "07"))
# # Process for subsetting
# llid_kelly = llid_kelly %>%
#   rename(geometry = Shape) %>%
#   select(llid = LLID, gnis_name = GNIS_STREAMNAME, llid_name = LLID_STREAMNAME,
#          wria_code, geometry)
# #unique(llid_kelly$wria_code)
# write_sf(llid_kelly, "data/llid_kelly_2020-03-12.gpkg")
# Get Arleta's latest llid data
llid_kelly = read_sf("data/llid_kelly_2020-03-12.gpkg",
                      layer = "llid_kelly_2020-03-12", crs = 2927)

#===========================================================================================
# Update some names in the database Trib 0204 to Trib 0205 & Trib 0202 to 0203
#===========================================================================================

# # Correct Trib 0204 in local DB
# qry = glue("update waterbody_lut set ",
#            "waterbody_name = 'Tributary 0205', ",
#            "waterbody_display_name = 'Tributary (22.0205)', ",
#            "stream_catalog_code = '22.0205' ",
#            "where waterbody_id = '59bfc1fb-8596-405c-92a2-cdf23e7fef9e'")
# # Update
# db_con = pg_con_local(dbname = "spawning_ground")
# DBI::dbExecute(db_con, qry)
# dbDisconnect(db_con)
#
# # Correct Trib 0204 in prod DB
# qry = glue("update spawning_ground.waterbody_lut set ",
#            "waterbody_name = 'Tributary 0205', ",
#            "waterbody_display_name = 'Tributary (22.0205)', ",
#            "stream_catalog_code = '22.0205' ",
#            "where waterbody_id = '59bfc1fb-8596-405c-92a2-cdf23e7fef9e'")
# # Update
# db_con = pg_con_prod(dbname = "FISH")
# DBI::dbExecute(db_con, qry)
# dbDisconnect(db_con)
#
# # Correct Trib 0202 in local DB
# qry = glue("update waterbody_lut set ",
#            "waterbody_name = 'Tributary 0203', ",
#            "waterbody_display_name = 'Tributary (22.0203)', ",
#            "stream_catalog_code = '22.0203' ",
#            "where waterbody_id = '59737d0c-0568-4fa5-b8b0-5d66e1137a69'")
# # Update
# db_con = pg_con_local(dbname = "spawning_ground")
# DBI::dbExecute(db_con, qry)
# dbDisconnect(db_con)
#
# # Correct Trib 0202 in prod DB
# qry = glue("update spawning_ground.waterbody_lut set ",
#            "waterbody_name = 'Tributary 0203', ",
#            "waterbody_display_name = 'Tributary (22.0203)', ",
#            "stream_catalog_code = '22.0203' ",
#            "where waterbody_id = '59737d0c-0568-4fa5-b8b0-5d66e1137a69'")
# # Update
# db_con = pg_con_prod(dbname = "FISH")
# DBI::dbExecute(db_con, qry)
# dbDisconnect(db_con)

#===========================================================================================
# Add streams one at a time
#===========================================================================================

#======== West Cady Creek =============================

# Check for previously assigned surveys: Result:

# Set stream llid....from QGIS...Arleta's latest
ll_id = '1213182478994'

# Get stream geometry from Arleta's layer
st_llid = llid_kelly %>%
  filter(llid == ll_id)

# Check crs
st_crs(st_llid)$epsg

#===== Verify stream is not already in SG based on stream_name or cat_coe ==================

# Get info from cat_llid
st_cat = cat_llid_kelly %>%
  filter(llid == ll_id | stringi::stri_detect_fixed(cat_name, "Cady", max_count = 1))

# Check if the waterbody_id already exists in stream table
wb_id = streams_st %>%
  filter(llid == ll_id)

# Check if the waterbody_id already exists in stream table
wb_id_2 = streams_st %>%
  filter(stringi::stri_detect_fixed(waterbody_display_name, "Cady", max_count = 1))

#============ Manually inspect in QGIS, then enter new stream data here =====================

# Create new entry in waterbody_lut
wb = tibble(waterbody_id = remisc::get_uuid(1L),
            waterbody_name = "West Cady Creek",
            waterbody_display_name = "W Cady Cr (07.1142)",
            latitude_longitude_id = ll_id,
            stream_catalog_code = "07.1142",
            tributary_to_name = "NF Skykomish R",
            obsolete_flag = 0L,
            obsolete_datetime = as.POSIXct(NA))

# # Correct mistake on display name
# wb = wb %>%
#   mutate(waterbody_display_name = "Little Hoquiam R (22.0155)")
#
# # Correct in DB
# qry = glue("update waterbody_lut ",
#            "set waterbody_display_name = 'Little Hoquiam R (22.0155)' ",
#            "where waterbody_id = '1d1cf340-ff02-4752-8789-834bf1d4e5e9'")
# # Update
# db_con = pg_con_local(dbname = "spawning_ground")
# DBI::dbExecute(db_con, qry)
# dbDisconnect(db_con)

# Write to local
db_con = pg_con_local(dbname = "spawning_ground")
dbWriteTable(db_con, 'waterbody_lut', wb, row.names = FALSE, append = TRUE)
dbDisconnect(db_con)

# Write to prod
db_con = pg_con_prod(dbname = "FISH")
tbl = Id(schema = "spawning_ground", table = "waterbody_lut")
DBI::dbWriteTable(db_con, tbl, wb, row.names = FALSE, append = TRUE, copy = TRUE)
dbDisconnect(db_con)

# Write stream to local =======================

# Get last gid local
qry = glue("select max(gid) as gid from stream")
# Run query
db_con = pg_con_local(dbname = "spawning_ground")
max_gid_local = dbGetQuery(db_con, qry)
dbDisconnect(db_con)

# Generate new gid
new_gid_local = max_gid_local$gid + 1L
# gid = 3666L

# Pull out wb_id
new_wb_id = wb$waterbody_id

# Create stream
stream_st = st_llid %>%
  mutate(stream_id = remisc::get_uuid(1L)) %>%
  mutate(waterbody_id = new_wb_id) %>%
  mutate(gid = new_gid_local) %>%
  mutate(created_datetime = with_tz(Sys.time(), tzone = "UTC")) %>%
  mutate(created_by = Sys.getenv("USERNAME")) %>%
  mutate(modified_datetime = as.POSIXct(NA)) %>%
  mutate(modified_by = NA_character_) %>%
  select(stream_id, waterbody_id, gid, geom, created_datetime,
         created_by, modified_datetime, modified_by)

# Write temp table
db_con = pg_con_local(dbname = "spawning_ground")
st_write(obj = stream_st, dsn = db_con, layer = "stream_temp")
dbDisconnect(db_con)

# Use select into query to get data into stream
qry = glue::glue("INSERT INTO stream ",
                 "SELECT CAST(stream_id AS UUID), CAST(waterbody_id AS UUID), ",
                 "gid, geom, ",
                 "CAST(created_datetime AS timestamptz), created_by, ",
                 "CAST(modified_datetime AS timestamptz), modified_by ",
                 "FROM stream_temp")

# Insert select to DB
db_con = dbConnect(odbc::odbc(), dsn = "local_spawn", timezone = "UTC")
DBI::dbExecute(db_con, qry)
DBI::dbDisconnect(db_con)

# Drop temp
db_con = pg_con_local(dbname = "spawning_ground")
DBI::dbExecute(db_con, "DROP TABLE stream_temp")
DBI::dbDisconnect(db_con)

# Write stream to prod =======================

# Get last gid prod
qry = glue("select max(gid) as gid from spawning_ground.stream")
# Run query
db_con = pg_con_prod(dbname = "FISH")
max_gid_prod = dbGetQuery(db_con, qry)
dbDisconnect(db_con)

# Generate new gid
new_gid_prod = max_gid_prod$gid + 1L
# gid = 3666L

# Verify gids match
if (!new_gid_local == new_gid_prod) {
  cat("\nWARNING: Adjust gid below before writing!!!\n\n")
} else {
  cat("\nGIDs match. Ok to proceed.\n\n")
}

# Write prod temp table
db_con = pg_con_prod(dbname = "FISH")
tbl = Id(schema = "spawning_ground", table = "stream_temp")
st_write(obj = stream_st, dsn = db_con, layer = tbl)
dbDisconnect(db_con)

# Use select into query to get data into stream
qry = glue::glue("INSERT INTO spawning_ground.stream ",
                 "SELECT CAST(stream_id AS UUID), CAST(waterbody_id AS UUID), ",
                 "gid, geom, ",
                 "CAST(created_datetime AS timestamptz), created_by, ",
                 "CAST(modified_datetime AS timestamptz), modified_by ",
                 "FROM spawning_ground.stream_temp")

# Insert select to DB
db_con = dbConnect(odbc::odbc(), dsn = "prod_fish_spawn", timezone = "UTC")
DBI::dbExecute(db_con, qry)
DBI::dbDisconnect(db_con)

# Drop temp
db_con = pg_con_prod(dbname = "FISH")
DBI::dbExecute(db_con, "DROP TABLE spawning_ground.stream_temp")
DBI::dbDisconnect(db_con)

