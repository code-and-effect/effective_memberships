// # When any data-applicant-experiences-month changes, sum them all up.
function sumApplicantExperiences($form) {
  let months = 0;

  // Sum each nested fields
  $form.find('.has-many-fields:visible').each(function() {
    const $obj = $(this);

    const start_on = $obj.find("input[name$='[start_on]']").val();
    const end_on = $obj.find("input[name$='[end_on]']").val();

    const level = $obj.find("input[name$='[level]']:checked").val();
    const percent = $obj.find("input[name$='[percent_worked]']").val() || 0;

    let diff = (moment(end_on).diff(moment(start_on), 'months') || 0);

    if(level == 'Part Time') {
      diff = Math.floor(diff * (percent / 100000.0)) // 100%
    }

    $obj.find("p[id$='_months']").text(diff);

    if(diff > 0) { months += diff; }
  });

  // Sum Total
  $form.find('p#applicant_applicant_experiences_months').text(months);
};

$(document).on('change dp.change keyup', "[data-applicant-experiences-month]", function(event) {
  const $form = $(event.currentTarget).closest('form');
  sumApplicantExperiences($form);
});


// $(document).on 'cocoon:after-remove', (event) ->
//   $form = $(event.target).closest('form')
//   sumMonths($form) if $form.find('[data-experience-month]').length > 0
