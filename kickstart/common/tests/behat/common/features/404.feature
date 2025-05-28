Feature:
  As a system
  I want to make not-found the following pages
  So user cannot access where they should not!

  Scenario Outline: 404 response
    When I go to "<url>"
    Then the response status code should be 404

    Examples:
      | url |
      | /url-not-found |
