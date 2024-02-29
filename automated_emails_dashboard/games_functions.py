import string 
import re
import sql_queries as sq
import games_symbols as gs

def update_games(games_user_input, mapping_dict):
    games_lst = games_user_input.split(',')
    games = [g.upper().strip() for g in games_lst]
    # remove any punctuation from the games provided
    no_punct_games = [g.translate(str.maketrans('', '', string.punctuation)) for g in games]
    updated_games = []
    for game in no_punct_games:
        # remove all symbols based on the dictionary values
        pattern = re.compile('|'.join((re.escape(symbol) for symbol in mapping_dict.keys())))
        single_digit_pattern = r'\b\d\b(?!\\d)'
        # if there numbers in the string or there are apostrophes
        if len(re.findall(single_digit_pattern, game)) > 0 or game.count('\S') > 0 or  game.count('\T') > 0:
            cleaned_game = pattern.sub(lambda x: mapping_dict[x.group()], game)
        else:
            cleaned_game = game
        updated_games.append(cleaned_game)

    return updated_games

def games_operators_logic(games_type):
    """
    The function created correct conditionals based on whether to include or exclude games
    """
    if games_type == 'excluded':
        game_string = ' AND '
        # need to use "and" instead of "or" for excluded games
        operator = 'AND'
        logic_exp = 'NOT'
    else:
       # "or" for included games
        operator = 'OR'
        game_string = ''
        logic_exp = ''

    return game_string, logic_exp, operator

def iterate_through_games(games_lst, game_type):
    game_string, logic_exp, operator = games_operators_logic(game_type)
    for ind, game in enumerate(games_lst):
        if ind > 0 and ind < len(games_lst):
            game_string += f"{operator} game {logic_exp} LIKE '%{game}%' "
        else:
            game_string += f"game {logic_exp} LIKE '%{game}%' "

    return game_string

def games_query_filter(updated_games_list=[], updated_excluded_games_list=[]):
    game_string = 'WHERE '
    bracket_one, bracket_two = ('', '')
    # handle two possibilities, when a requester specifies games to include and/or games to exclude
    if len(updated_games_list) > 0:    
        included_games = iterate_through_games(updated_games_list, 'included')
    else:
        included_games= ''
    if len(updated_excluded_games_list) > 0:
        excluded_games = iterate_through_games(updated_excluded_games_list, 'excluded')
        if len(updated_games_list) > 0:
            bracket_one = '(' 
            bracket_two = ')'
        else:
            # remove " AND " part from the beginning if there are no included games
            excluded_games = excluded_games[5:]
    else:
        excluded_games = ''
    resulting_string = game_string + f'{bracket_one}' + included_games + f'{bracket_two}' + excluded_games + ')'

    return resulting_string

def handle_games(responses_dictionary):
    game_query = sq.activity_query_dict['games'].format(activity_time_answer=responses_dictionary['time_period'])
    if len(responses_dictionary['games']) > 0:
        updated_games_lst = update_games(responses_dictionary['games'], gs.game_symbol_dict)
    else:
        updated_games_lst = []
    if len(responses_dictionary['excluded_games']) > 0:
        updated_excluded_games_lst = update_games(responses_dictionary['excluded_games'], gs.game_symbol_dict)
        query_end = games_query_filter(updated_games_lst, updated_excluded_games_lst)
    else:
        query_end = games_query_filter(updated_games_lst)
    product_sql = game_query + query_end
    # product response

    return product_sql