$(function(){
  $('[data-toggle=tooltip]').tooltip();

  $('.datepicker').datepicker({
    todayBtn: 'linked',
    autoclose: true,
    todayHighlight: true,
    format: "yyyy-mm-dd",
  });
});
