## Automated Emails Request Tool
The purpose of this app is to automate simple data requests related to generating user email lists based on specified requirements.
The app is a dropdown form. There are two pages:
- **1_activity_emails_request**: requests related to user activity, e.g., all users active within the past 90 days. User can also specify product, subscriber status, country, excluded country, streamed games, excluded games, whether a user is subscribed to marketing emails.
- **2_ultra_subs_emails_request**: requests related specifically to Ultra subs, including status, created_at date range, cancellation_at date range, plan frequency, user country, excluded country(ies), whether or not a user is subscribed to marketing emails.
-**utils.py** file contains queries and helper functions utilized by the two pages.

##### To run the app
```
streamlit run intro_page.py
```

##### Destinations
The report will be saved in s3 under:
```
streamlabs-analytics/automated_email_reports/activity_email_report/ + [created_date]
```
or 
```
streamlabs-analytics/automated_email_reports/ultra_subs_email_report/ + [created_date]
```

Requester's name and execution timestamp will be in the file_name.

##### App Formatting and Color Scheme
The folder **.streamlit** contains a file called **config.toml** that specifies color scheme and font.
