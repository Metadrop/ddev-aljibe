Feature: As a user
  I want to manage cookies
  So that I can protect my GDPR!

  # This test only makes sense if the cookie banner is displayed. As a new
  # Drupal project does not provide one, this test has been partially commented
  # out to avoid triggering a failure during tests. Uncomment and adjust as
  # needed when a cookie banner is available.

  @javascript @cookies
  Scenario: Cookies banner check
    When I go to "/en/"

    ### Steps commented out below need a cookie banner to work properly.
    # When I wait for the cookie banner to appear
    # Then I wait for "1" seconds
    # And there should not be any cookies loaded

    # When I accept cookies
    ### End of commented out steps.
    Then the cookies of "mandatory" type have been loaded
    Then the cookies of "analytics" type have been loaded
