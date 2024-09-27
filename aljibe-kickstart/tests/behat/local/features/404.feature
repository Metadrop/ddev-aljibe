Feature:
  As a Maintainer
  I want to check that some urls return not found code

  @behat
  Scenario: Homepage works
    Given I go to "/url-not-working"
    Then the response status code should be 404