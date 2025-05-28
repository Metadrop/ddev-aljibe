Feature:
  As a system
  I want to block the following pages
  So user cannot access where they should not!

  Scenario Outline: 403 response
    When I go to "<url>"
    Then the response status code should be 403

    Examples:
      | url |
      | /admin |
      | /user/register |
