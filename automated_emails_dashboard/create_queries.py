# create sql based on responses run through response functions
import form_responses as fr
import sql_queries as sq
import games_functions as gf

def create_activity_sql(responses_dictionary):
    """ The function takes answers from web app and creates the sql query based on answers
     Params:
        responses dictionary - a dictionary that holds all user inputs.
          """
    subs_status_cte_sql, subs_status_join_sql, subs_filter = fr.handle_user_status(responses_dictionary['paid_sub_status'],
                                                                                   sq.activity_query_dict['subs_cte'])
    marketing_email_sql = fr.handle_marketing_email(responses_dictionary['subscribed_to_email'])
    country_sql = fr.handle_country(responses_dictionary)
    if country_sql != 'invalid':
        base_query = fr.handle_base_query(responses_dictionary['games'],
                                       subs_status_join_sql,
                                       subs_filter,
                                       marketing_email_sql,
                                       country_sql)
        activity_time_answer = responses_dictionary['time_period']
        # if user selects games
        if len(responses_dictionary['games']) > 0 or len(responses_dictionary['excluded_games']):
            product_sql = gf.handle_games(responses_dictionary)
        # product response
        else:
            if responses_dictionary['product'] == 'Both (Desktop and/or Web)':
                product_sql = sq.activity_query_dict["desktop_or_web"].format(activity_time_answer=activity_time_answer)
            elif responses_dictionary['product'] == 'Desktop':
                product_sql = '' + sq.activity_query_dict["desktop"].format(activity_time_answer=activity_time_answer)
            else:
                product_sql = '' + sq.activity_query_dict["web"].format(activity_time_answer=activity_time_answer)
        final_sql = "" + product_sql + subs_status_cte_sql + base_query
    else:
        final_sql = 'invalid'

    return final_sql



def create_ultra_subs_sql(responses_dictionary):
    """
    The function generates a base query depending on whether we need games

    If the user inputs 'All Countries' and also adds exclusion countries then set the final sql = 'invalid' so the report shows an error before running
    """
    country_sql = fr.handle_country(responses_dictionary) 
    if country_sql != 'invalid':    
        status_sql = fr.handle_sub_status(responses_dictionary['paid_sub_status'])
        created_date_sql = fr.handle_created_date_range(responses_dictionary['created_time_period'])
        cancelled_date_sql = fr.handle_cancelled_date_range(responses_dictionary['cancelled_time_period'])
        freq_sql = fr.handle_frequency(responses_dictionary['sub_frequency'])
        marketing_sql = fr.handle_marketing_email(responses_dictionary['subscribed_to_email'])
        final_sql = sq.subs_query_dict['subs_query'].format(status_sql=status_sql,
                                                                            created_date_sql=created_date_sql,
                                                                            cancelled_date_sql= cancelled_date_sql,
                                                                            freq_sql=freq_sql,
                                                                            marketing_sql=marketing_sql,
                                                                            country_sql=country_sql)
    else:
        final_sql = 'invalid'
    
    return final_sql
