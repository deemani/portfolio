import streamlit as st
import boto3
from pyathena import connect
from pyathena.pandas.cursor import PandasCursor
import create_forms as cf
import helper_functions as hf
import create_queries as cq
import sql_queries as sq
# set AWS Athena connection for query results and query output
staging_dir = 's3://company-analytics/query-results-bucket/automated_email_dashboard/'

cursor = connect(s3_staging_dir=staging_dir,
                 region_name='us-east-1'
                 ).cursor(PandasCursor)
s3_bucket = 'company-analytics'
report_folder = 'automated_email_reports/ultra_subs_email_report'
s3_region = 'us-east-0'
s3_resource = boto3.resource('s3', region_name=s3_region)

# run create ultra subs form function. responses_dictionary contains inputs from user. submit_button is boolean whether user pressed submit or not.
submit_button, responses_dictionary = cf.create_ultra_subs_email_form()

# when user clicks submit then submit_button = True, running query, creating CSV, outputting to S3, and printing out S3 location link
if submit_button:
    with st.spinner('Running report...'):
        final_query = cq.create_ultra_subs_sql(responses_dictionary)
        if final_query != 'invalid':
            print(final_query)
            report_df = cursor.execute(final_query).as_pandas()
            # generate the s3 destination and file name
            s3_file_path, file_name = hf.generate_s3_path(report_folder, responses_dictionary['requesters_name'])
            hf.save_to_csv_s3(report_df, s3_bucket, s3_resource, s3_file_path)
            report_file_url = hf.s3_url_link(s3_bucket, s3_region, report_folder)
            if report_df.email.nunique() == 0:
                st.error('🚨 The report returned 0 records. Please screenshot your inputs and contact the data team for assistance')
            else:
                st.write('##### Report Summary:')
                st.markdown(f'- Your email list is available at:{report_file_url}')
                st.write('- File name:', file_name)
                st.write('- The number of unique emails:', report_df.email.nunique())
                st.success('Done!')