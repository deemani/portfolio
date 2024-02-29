from datetime import date
import datetime
from io import StringIO

def truncate_to_minute(timestamp):
    """ takes timestamp and truncates it to the minute"""
    return timestamp.replace(second=0, microsecond=0)

def s3_url_link(s3_bucket, s3_region, report_folder):
    """
    Generates a clickable url to s3 folder that takes a requester directly to the file
    """
    today = str(date.today())
    base_url = 'https://s3.console.aws.amazon.com/s3/buckets/' 
    file_url = base_url + s3_bucket + '?region=' + s3_region + '&bucketType=general&prefix=' + report_folder + '/' + today + '/'

    return file_url

def generate_s3_path(folder, persons_name):
    file_name = ('email_list_' + persons_name.replace(" ", "_") + '_' + str(truncate_to_minute(datetime.datetime.now())).replace(" ", "_"))
    today = str(date.today())
    s3_file_path = folder + '/' + today + '/' + file_name + '.csv'

    return s3_file_path, file_name


def save_to_csv_s3(df, bucket, s3_resource, s3_destination):
    """ takes dataframe, bucket, s3 resource, and destination. converts dataframe to csv and saves to bucket/destination in s3"""
    csv_buffer = StringIO()
    df.to_csv(csv_buffer, index=False)
    # save the entire file to s3
    response = s3_resource.Object(bucket, s3_destination).put(Body=csv_buffer.getvalue())
    print('\tSaved to', s3_destination)
