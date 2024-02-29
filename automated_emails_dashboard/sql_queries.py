countries_query_dict = {"countries_query": "SELECT DISTINCT '"'|| name || '"' AS country FROM geographic.country_codes"}

activity_query_dict = {"subs_cte":
                          """,subs AS (
                            SELECT DISTINCT case
                                    when i.identifiable_id is null then s.user_id else i.identifiable_id
                                end as consolidated_user_id
                            FROM company_consolidated_db.subscriptions s
                                LEFT JOIN company.company_identities i ON s.sl_id = i.identity_id
                                LEFT JOIN company_consolidated_db.plans p ON s.plan_id = p.id
                            WHERE s.status in ('active')
                                and p.product = 'ultra'
                            )""",
                            "desktop_or_web":
                                 """WITH active AS (
                                SELECT distinct cast(s.user_id as bigint) as user_id
                                FROM product.desktop_daily_tracker s
                                WHERE day >= current_date - interval '{activity_time_answer}' day
                                GROUP BY 1
                                UNION
                                SELECT distinct sa.user_id as user_id
                                FROM company.streamer_activity sa
                                WHERE active_at >= current_date - interval '{activity_time_answer}' day
                                GROUP BY 1)""",
                                "desktop":
                                """ WITH active AS (
                                SELECT distinct cast(s.user_id as bigint) as user_id
                                FROM product.desktop_daily_tracker s
                                WHERE day >= current_date - interval '{activity_time_answer}' day
                                GROUP BY 1
                                )""",
                               "web":
                                    """
                                    WITH active AS (
                                    SELECT distinct sa.user_id as user_id
                                    FROM company.streamer_activity sa
                                    WHERE active_at >= current_date - interval '{activity_time_answer}' day
                                    GROUP BY 1
                                    )""",
                                "base_query": 
                                            """
                                            SELECT distinct u.email
                                                FROM active a
                                                    LEFT JOIN geographic.user_country uc ON a.user_id = uc.user_id
                                                    LEFT JOIN geographic.country_codes cc on uc.country = cc.alpha_2
                                                    LEFT JOIN company.user_settings s ON a.user_id = s.user_id
                                                    JOIN company.users u ON u.id = a.user_id
                                                    {subs_cte}
                                                WHERE u.email is not null
                                                    and u.email <> ''
                                                    {marketing_sql}
                                                    {country_sql}
                                                    {subs_filter}
                                                    """,
                                "games":
                                       """WITH games AS (SELECT DISTINCT CASE WHEN REGEXP_LIKE(
                                            REGEXP_REPLACE(UPPER(TRIM(cast(json_extract(data, '$.game') as varchar))), 
                                            '[[:punct:]]', '')
                                            , '\s\d(?!\d)$') THEN 
                                            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                            REGEXP_REPLACE(UPPER(TRIM(cast(json_extract(data, '$.game') as varchar))), 
                                            '[[:punct:]]', '')
                                            , '1', 'I'), '2', 'II'),
                                            '3', 'III'), '4', 'IV'), '5', 'IV'),
                                            '6', 'VI'), '7', 'VII'), '8', 'VIII'), '9', 'IX'), '10', 'X') 
                                            ELSE 
                                            REGEXP_REPLACE(UPPER(TRIM(cast(json_extract(data, '$.game') as varchar))), 
                                            '[[:punct:]]', '')
                                            END AS game,
                                            CAST(user_id AS BIGINT) AS user_id
                                FROM
                                    product.desktop_tracker t
                                WHERE
                                    date(created_at) >= current_date - interval '{activity_time_answer}' day
                                    AND UPPER(cast(json_extract(data, '$.game') as varchar)) <> ''
                                    AND UPPER(cast(json_extract(data, '$.game') as varchar)) IS NOT NULL
                                    and event = 'stream_start')
                                , active AS (SELECT user_id, 
                                                    game 
                                                FROM games
                                    """

                    }

subs_query_dict = {"subs_query":
                                        """WITH subs AS (
                                                SELECT DISTINCT case
                                                        when i.identifiable_id is null then s.user_id else i.identifiable_id
                                                    end as consolidated_user_id
                                                FROM company_consolidated_db.subscriptions s
                                                    LEFT JOIN company.company_identities i ON s.sl_id = i.identity_id
                                                    LEFT JOIN company_consolidated_db.plans p ON s.plan_id = p.id
                                                WHERE p.product = 'ultra'
                                                    {status_sql}
                                                    {freq_sql}
                                                    {created_date_sql}
                                                    {cancelled_date_sql}
                                            )
                                            SELECT distinct u.email
                                            FROM subs b
                                                LEFT JOIN geographic.user_country uc ON b.consolidated_user_id = uc.user_id
                                                LEFT JOIN geographic.country_codes cc on uc.country = cc.alpha_2
                                                LEFT JOIN company.user_settings s ON b.consolidated_user_id = s.user_id
                                                JOIN company.users u ON u.id = b.consolidated_user_id
                                            WHERE u.email is not null
                                                and u.email <> '' 
                                                {marketing_sql} 
                                                {country_sql}
                                        """
                        }