Feature:
  As a user
  I want to visit the following pages
  So that I know production site is working!

  Scenario Outline: 200 response
    When I go to "<url>"
    Then the response status code should be 200

    Examples:
      | url |
      | /user/login   |
