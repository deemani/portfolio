import streamlit as st
import sql_queries as sq


def all_countries_logic(country_response):
    """"
    The function generates selected country sql
    """
    if 'All Countries' in country_response:
            country_sql = ''
    else:
        country_sql = 'and cc.name in (' + ', '.join(["'{}'".format(value) for value in country_response]) + ')'

    return country_sql

def create_country_exception(responses_dictionary):
    excl_country = responses_dictionary['excluded_country']
    if 'All Countries' in responses_dictionary['country'] and len(responses_dictionary['excluded_country']) > 0:
        error_message = f"""
                         :red[**Invalid Selection**]: cannot exclude **{excl_country}** when users from **\"All Countries\"** is selected.
                         - Deselect **"All Countries"** from the field _"Users from the following countries"_.
                         - Select **{excl_country}** in the field _"EXCLUDE these countries"_.
                        """      
    else:
        error_message = ''

    return  error_message

def handle_marketing_email(response):
    """
    This function generates the part of the WHERE clause for a user's marketing email subscription status
    """
    # marketing email response
    if response == 'Yes, only users who are subscribed to marketing emails':
        marketing_email_sql = 'and s.subscribed = 1'
    else:
        marketing_email_sql = ''

    return marketing_email_sql

def handle_country(responses_dictionary):
    print(responses_dictionary['country'], responses_dictionary['excluded_country'])
    # if countries response is provided
    if len(responses_dictionary['country']) > 0 and len(responses_dictionary['excluded_country']) == 0:
        country_sql = all_countries_logic(responses_dictionary['country'])
    elif len(responses_dictionary['country']) > 0 and len(responses_dictionary['excluded_country']) > 0:
        # in case users select all countries but also want to exclude a country
        error_message = create_country_exception(responses_dictionary)    
        if error_message != '':
            st.write(error_message)
            country_sql = 'invalid'
        else:
            country_one = all_countries_logic(responses_dictionary['country'])
            excluded_country_sql = 'and cc.name NOT IN (' + ', '.join(["'{}'".format(value) for value in responses_dictionary['excluded_country']]) + ')'
            country_sql = country_one + excluded_country_sql
    elif len(responses_dictionary['country']) == 0 and len(responses_dictionary['excluded_country']) > 0:
        country_sql = 'and cc.name NOT IN (' + ', '.join(["'{}'".format(value) for value in responses_dictionary['excluded_country']]) + ')'
    else:
        # if neither is selected
        country_sql = ''  
    
    return country_sql

def handle_user_status(response, subs_status_cte_sql):
    subs_status_join_sql = 'LEFT JOIN subs b ON a.user_id = b.consolidated_user_id'
    if response =='Paid':
        subs_filter = 'AND b.consolidated_user_id IS NOT NULL'
    elif response == 'Free':
        subs_filter = 'AND b.consolidated_user_id IS NULL'
    else:
        subs_status_cte_sql = ''
        subs_status_join_sql = ''
        subs_filter = ''

    return subs_status_cte_sql, subs_status_join_sql, subs_filter

# activity form specific_functions

def handle_base_query(games, subs_cte, subs_filter, marketing_sql, country_sql):
    """
    The function generates a base query
    deneding on whether we need games
    """
    base_query = sq.activity_query_dict['base_query'].format(subs_cte=subs_cte,
                                                             subs_filter=subs_filter,
                                                             marketing_sql=marketing_sql,
                                                             country_sql=country_sql)
    if len(games) > 0:
        resulting_base_query = base_query.replace('distinct u.email',
                                                  'distinct u.email, a.game')
    else:
        resulting_base_query = base_query

    return resulting_base_query

# ultra subscription form specific functions

def handle_sub_status(response):
    
    if 'Either Active or Canceled' in response:
        status_sql = ''
    else:
        status_sql = "and status in ('" + response.lower() + "')"
    
    return status_sql

def handle_frequency(response):
    if len(response) > 0:
        if 'All' in response:
            freq_sql = ''
        else:
            freq_sql = 'and p.frequency in ('+ ', '.join(["'{}'".format(value) for value in response]).lower() + ')'
    else:
        freq_sql = ''
    
    return freq_sql

def handle_created_date_range(response):
    """
    this function takes the user's selected date range of subscription creation and generates the SQL for the WHERE clause
    """
    if response:
        created_date_sql = "and date(s.created_at) >= date('" + str(response[0]) + "') and date(s.created_at) <= date('" + str(response[1]) + "')"
    else:
       created_date_sql = ''
    
    return created_date_sql

def handle_cancelled_date_range(response):
    """
    this function takes the user's selected date range of subscription cancellation and generates the SQL for the WHERE clause
    """
    if response:
        cancelled_date_sql = "and date(s.cancelled_at) >= date('" + str(response[0]) + "') and date(s.cancelled_at) <= date('" + str(response[1]) + "')"
    else:
        cancelled_date_sql = ''
    
    return cancelled_date_sql
