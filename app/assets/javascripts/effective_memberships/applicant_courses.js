// # When any data-applicant-experiences-month changes, sum them all up.
function sumApplicantCourses($form) {
  // For each area
  $form.find('.applicant-course-area').each(function() {
    const $area = $(this);

    let sum = 0;

    $area.find('input[data-applicant-courses-amount]').each(function() {
      sum += parseInt($(this).val() || 0);
    });

    $area.find('[data-applicant-course-area-sum]').text(sum);
  });

  // For everything
  let sum = 0;

  $form.find('input[data-applicant-courses-amount]').each(function() {
    sum += parseInt($(this).val() || 0);
  });

  $form.find('[data-applicant-courses-sum]').text(sum);
};

$(document).on('change dp.change keyup', "[data-applicant-courses-amount]", function(event) {
  const $form = $(event.currentTarget).closest('form');
  sumApplicantCourses($form);
});
