function get_user_state() {
  if( expect_logged_in() ) {
    return 'logged_in';
  } else {
    return 'logged_out';
  }
}

function get_page_type() {
  if( window.location.pathname.match(/^\/articles\/search/) === null ) {
    return 'article';
  } else {
    return 'search';
  }
}

function get_folder_type(folder_slug) {
  if( folder_slug == 'my-clippings' ) {
    return 'clipboard';
  } else {
    return 'folder';
  }
}

function track_clipping_event(action, document_number, folder_slug) {
  /* current actions: add, remove */

  user_state  = get_user_state();
  page_type   = get_page_type();
  folder_type = get_folder_type(folder_slug);

  label = user_state + "/" + folder_type + "/" + page_type + "/" + document_number;

  _gaq.push(['_trackEvent', 'Clipping', action, label]);
}

function track_folder_event(action, document_count) {
  /* current actions: create */

  user_state  = "logged_in";
  page_type   = get_page_type();
  folder_type = "folder";

  label = user_state + "/" + folder_type + "/" + page_type;

  _gaq.push(['_trackEvent', 'Folder', action, label, document_count]);
}


$(document).ready(function(){
  // NAVIGATION
  $(".dropdown.nav_myfr2 ul.subnav li a").each(function() {
    $(this).bind('click', function() {
      _gaq.push(['_trackEvent', 'Navigation', 'MyFR', $(this).html()]);
    });
  });
});
