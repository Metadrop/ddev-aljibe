Feature:
  As a Maintainer
  I want to check that blocked pages are not accesible

  @behat
  Scenario: Admin area is not accesible
    Given I go to "/admin"
    Then the response status code should be 403

  @behat
  Scenario: User root profile page is not acccesible
    Given I go to "/user/1"
    Then the response status code should be 403

  @behat
  Scenario: User register page is not acccesible
    Given I go to "/user/register"
    Then the response status code should be 403
