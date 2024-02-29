import streamlit as st

st.title("Welcome to Analytic's Self-Service Email Tools! ")

st.markdown("""
            This site contains tools that allow you
            to generate lists of user emails
            for specific Streamlabs products.
            Currently, there are two types of requests available:
            - :red[**activity emails requests:**] users' email
            list based on their activity in
            the specified period, geography, streamed game, and marketing email
            subscriber status.
            - :red[**ultra subs emails requests:**] email list
            for ultra current or past subscribers
            based on their subscription status, plan, plan creation and
            cancellation date ranges,
            country, and marketing email subscriber status.
            The tools are listed by product, with each product
            having a variety of forms to use.
            If you do not see an option for your desired email
            list then please submit a Data Team
            request for a new form and we will be happy to add it.
            """)
# st.sidebar.success("Select a product")
