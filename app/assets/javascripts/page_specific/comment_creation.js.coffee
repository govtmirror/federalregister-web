$(document).ready ->
  commentLink = $('a#start_comment[data-comment=1]').get(0)

  if commentLink || window.location.hash == "#open-comment"
    FR2.commentFormHandlerInstance = new FR2.CommentFormHandler(
      $('#flash_message.comment')
    )
