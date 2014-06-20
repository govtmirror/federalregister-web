class @FR2.CommentFormSuccessHandler
  constructor: (commentFormHandler)->
    @commentFormHandler = commentFormHandler

  initialize: ->
    @add_events()
    @updateCommentHeader()

  formWrapper: ->
    @commentFormHandler.formWrapper

  ajaxCommentData: ->
    $('.ajax-comment-data')

  add_events: ->
    @printComment()
    @analytics()

  updateCommentHeader: ->
    flashMessage = $('#flash_message.comment p')

    flashMessage
      .closest 'div'
      .removeClass 'open'

    flashMessage
      .html 'You have successfully submitted an official comment to Regulations.gov. <img alt="Regulations.gov Logo" src="/my/assets/regulations_dot_gov_logo.png" class="reg_gov_logo">'


  printComment: ->
    @ajaxCommentData().on 'click', 'a#print-comment', (e)->
      e.preventDefault()

      link = $(this)

      modalTitle    = 'Print your comment'
      modalTemplate = $("#comment-print-summary-template")
      modalData     = link.data('comment-data')

      compiledTemplate = Handlebars.compile modalTemplate.html()
      modalHtml        = compiledTemplate({
        fields: modalData
        document_details: link.data 'current-document-details'
        comment_details: link.data 'comment-details'
      })

      display_fr_modal modalTitle, modalHtml, link, {modalClass: "print_modal"}

      $('body').addClass 'hide_body_content'

    @formWrapper().on 'modalClose', 'a#print-comment', ->
      $('body').removeClass 'hide_body_content'

    $('body').on 'click', '#fr_modal .print_button', (e)->
      e.preventDefault()
      window.print()

  trackCommentEvent: (category)->
    @commentFormHandler.trackCommentEvent category

  analytics: ->
    @ajaxCommentData().on 'click', '.tracking_number', ()=>
      @trackCommentEvent 'Comment Success: Comment Tracking Number'

    @ajaxCommentData().on 'click', '.my_fr .notifications.posting.remove', ()=>
      @trackCommentEvent 'Comment Success: MyFR Posting Notification Opt Out'

    @ajaxCommentData().on 'click', '.my_fr .notifications.posting', ()=>
      @trackCommentEvent 'Comment Success: MyFR Posting Notification Opt In'

    @ajaxCommentData().on 'click', '.my_fr .notifications.followup.remove', ()=>
      @trackCommentEvent 'Comment Success: MyFR Posting Notification Opt Out'

    @ajaxCommentData().on 'click', '.my_fr .notifications.followup', ()=>
      @trackCommentEvent 'Comment Success: MyFR Posting Notification Opt In'

    @ajaxCommentData().on 'click', '#print-comment', ()=>
      @trackCommentEvent 'Comment Success: Print Comment'

    @ajaxCommentData().on 'click', '.social_media .twitter', ()=>
      @trackCommentEvent 'Comment Success: Social Media Twitter'

    @ajaxCommentData().on 'click', '.social_media .facebook', ()=>
      @trackCommentEvent 'Comment Success: Social Media Facebook'

    @ajaxCommentData().on 'click', '.warning.message .resend_email_confirmation', ()=>
      @trackCommentEvent 'Comment Success:  MyFR Resend Email Confirmation'

    @ajaxCommentData().on 'click', '.buttons .comment_form_sign_in', ()=>
      @trackCommentEvent 'Comment Success:  MyFR Sign In'

    @ajaxCommentData().on 'click', '.buttons .comment_form_sign_up', ()=>
      @trackCommentEvent 'Comment Success:  MyFR Sign Up'
