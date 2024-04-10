import streamlit as st

st.title('Welcome to My Book Recommendation Tool 📖')

st.markdown('''
            This tool takes a user's input and returns a list of recommended books. A user can search by author or book title and the recomended books will be based off of reviews of users who also enjoyed the input book/author.
            
            If a user searches by author, the tool will only return books from other authors. If the a user searches by book title, the tool will return any book that is not the input book.

            The recommendation tool will show the top 10 recommended book, their total number of reviews, and their average score.

            I defined a user liking a book as a score >= 4.

            The data is based off of ~2M Amazon book reviews for more than 100k Authors & 200k Books.

            Additionally, the Book Reveiw Stats page has some additional data & visualizations about the books & authors in the dataset.
            ''')

st.page_link("pages/1_Book_Recommendation_Tool_⚙️.py", label="Book Recommendation Tool", icon="⚙️")
st.page_link("pages/2_Book_Review_Stats_📈.py", label="Book Reviews Stats", icon="📈")
