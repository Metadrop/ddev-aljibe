Feature:
  As a user
  I want to visit the following pages
  So that I can browse the site!

  Scenario Outline: 200 response
    When I go to "<url>"
    Then the response status code should be 200

    Examples:
      | url |
      | /   |
      | /robots.txt   |
