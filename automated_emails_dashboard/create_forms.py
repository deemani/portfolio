import streamlit as st
import countries_list as cl

# create activity email report form
def create_activity_email_form():
    #  start of form
    with st.form("email_form"):
        # main title of form
        st.title('Activity Email List Form')
        responses_dictionary = { 
                                # dropdown single selectbox where user
                                # determines which product's activity to include
                                'product': st.selectbox(label="Users who had activity in:",
                                                        options=['Both (Desktop and/or Web)', 
                                                                 'Desktop', 
                                                                 'Web']),
                                # numeric input that determines how many days to look back for
                                # activity. min value is 1, defaults to 60.
                                'time_period': st.number_input(label='Users who had activity within the last X days:',
                                                              min_value=1,
                                                              value=60),
                                # dropdown multiselect which takes user input for which countries to limit query.
                                # options are the countries object, defaults to All Countries
                                'country': st.multiselect(label='Users from the following countries:',
                                                          options=cl.countries,
                                                          default='All Countries'),
                                # exclude these countries
                                'excluded_country': st.multiselect(label='**:red[EXCLUDE]** these countries (Optional):',
                                                                   options=cl.countries,
                                                                   placeholder='Specify countries to exclude'),
                                # dropdown single select which takes user input on whether to limit
                                # to user's who are actively subscribed,
                                # not subscribed or either status
                                'paid_sub_status': st.selectbox(label='Users whose current subscription status is:',
                                                                options=['Either (Free or Paid)', 'Free', 'Paid']),
                                # a free text form where users enter streamed games separated by a comma
                                'games': st.text_input(label='Streamed Games (Optional):',
                                                       placeholder='Type a list of games separated by a comma (no abbreviations)'),
                                # a free text form where users enter games to exclude
                                'excluded_games': st.text_input(label='**:red[EXCLUDE]** these games (Optional):',
                                                                placeholder='Type a list of games to exclude separated by a comma (no abbreviations)'),
                                # dropdown single select which checks whether to limit only
                                # to users who have subscribed to marketing emails or not
                                'subscribed_to_email': st.selectbox(label='Users who are subscribed to marketing emails:',
                                                                    options=['Yes, only users who are subscribed to marketing emails', 
                                                                             'No, any user']),
                                # free text field which takes the user name to be appended to the file nam
                                'requesters_name': st.text_input(label='Enter your name',
                                                                 placeholder='First Last')}

        # creates a submit button which will run the rest of the script
        submit_button = st.form_submit_button("Submit")

        return submit_button, responses_dictionary
    

# create subscriptions email report form
def create_ultra_subs_email_form():
    with st.form("subs_email_form"):
        # main title of form
        st.title('Subscriber Email List Form')

        # dropdown single selectbox for subscribed user status
        sub_status_select = st.selectbox(label='Users whose current subscription status is:',
                                        options=['Active', 'Canceled', 'Either (Active or Canceled)'])
        
        # date range for subcription created_at range (optional)
        sub_created_date_range = st.date_input(label = 'Subscription created date range: (optional)',
                                            value = ())
        
        # date range for subcription cancelled_at range (optional)
        sub_cancelled_date_range = st.date_input(label = 'Subscription cancellation date range: (optional)',
                                            value = ())
        
        #  dropdown single selectbox for subscribers plan frequency 
        sub_freq_input = st.multiselect(label="Subscribers with a plan billing frequency of:",
                                        options= ['All', 'Monthly', 'Yearly', 'Quarterly', 'Sesquiennial'],
                                        default='All')
        
        # dropdown multiselect which takes user input for which countries to limit query. options are the countries object, defaults to All Countries
        country_multi = st.multiselect(label = 'Subscribers from the following countries:',
                                        options=cl.countries,
                                        default='All Countries')
        # exclude these countries
        country_excl_multi = st.multiselect(label='**:red[EXCLUDE]** subscribers from these countries (Optional):',
                                        options=cl.countries,
                                        placeholder='Specify countries to exclude')
                                    
        # dropdown single select which takes user input on whether to limit only to users who have subscribed to marketing emails or not
        marketing_email_check = st.selectbox(label='Users who are subscribed to marketing emails:',
                                            options=['Yes, only users who are subscribed to marketing emails', 'No, any user'])    

        # free text field which takes the user name to be appended to the file name
        name_text = st.text_input(label='Enter your name',
                                placeholder='First Last')

        # record all responses in one dictionary
        responses_dictionary = {'paid_sub_status': sub_status_select,
                                'created_time_period': sub_created_date_range,
                                'cancelled_time_period': sub_cancelled_date_range,
                                'sub_frequency': sub_freq_input,
                                'country': country_multi,
                                'excluded_country': country_excl_multi,
                                'subscribed_to_email': marketing_email_check,
                                'requesters_name': name_text}
        
        # creates a submit button which will run the rest of the script    
        submit_button = st.form_submit_button("Submit")

        return submit_button, responses_dictionary

