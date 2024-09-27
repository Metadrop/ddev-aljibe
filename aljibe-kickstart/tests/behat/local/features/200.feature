Feature:
  As a Maintainer
  I want to check that main pages are accesible

  @behat
  Scenario: Homepage is working
    Given I go to "/"
    Then the response status code should be 200

  @behat
  Scenario: Robots.txt is working
    Given I go to "/robots.txt"
    Then the response status code should be 200

#  @behat
#  Scenario: Sitemap is working
#    Given I go to "/sitemap.xml"
#    Then the response status code should be 200