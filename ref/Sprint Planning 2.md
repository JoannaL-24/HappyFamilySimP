

# **Happy Family Sim**

**Sprint 2 Planning Document**  
Team 21: Joanna Lin, Taylor Huang, William Hou, Zoey Lu

## Sprint Overview:

After establishing the foundational architecture in Sprint 1, we aim to build more advanced features and improve the overall user experience in this sprint, including the UI, the gaming part, and task creation, assignment, submission, and review. Task completion and gaming are connected by adding the reward feature. Key deliverables include:

* **Task Assignment**: Enabling parents to choose from a set of pre-populated tasks and assign a task to multiple children.   
* **Reviewing Tools and Rewards**: Allowing the children to submit completed tasks for review. Parents are able to reject or accept a task and decide what kind of resources to give their children upon the acceptance of a task.  
* **User Experience**: Beautify and unify the UI throughout the app.  
* **Game**: Implementing features for the children to interact with their virtual animal. Children can apply resources, receive items, and see the states of their virtual animal.

By the end of this sprint, the team aims to have a functional pipeline where a parent can assign and review a chore and a child can interact with their creature within the integrated game engine.

**Scrum Master:** Joanna Lin

**Meeting Schedule:** MWF at 7 PM

### Risks and Challenges:

- Finding suitable art assets and/or drawing them ourselves  
- Although we learned the basics of Flutter and Supabase during the previous sprint, the features to be implemented in this sprint may require more advanced skills or tools.  
- Modifying the UI and adding new parts to the workflow may induce a lot of changes to what we have built in the previous sprint.

## **Current Sprint Detail**

## User Account & Authentication:

**User Story \#1-4 (from previous sprint)**  
As a parent, I would like to reset my password if I forget it.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Move the webpage for password reset to the project repository. | 1 Hrs | Zoey |
| 2 | Modify the email content so that the user can tell which email is for our app. | 0.5 Hrs | Zoey |
| 3 | Test to verify that this works for Android, iOS, and Chrome. | 2 Hrs | Zoey |

Acceptance criteria:

1. Given that the “forgot password” UI is implemented correctly, I, as a parent, should be able to enter my email address and request a password reset.  
2. Given that the email sending system using the Supabase API is implemented correctly, I, as a parent with a valid account, should receive an email containing a password reset link.  
3. Given that the authentication verification system is implemented correctly, I, as a parent, should be able to enter the authentication code and successfully reset my password before the link expires.

4. Given that the password reset link has expired, I, as a parent, should be notified that the link is no longer valid and be required to request a new password reset link.

## Task Creation & Assignment (Parent):

**User Story \#2-3**  
As a parent, I would like to set a task to repeat on a daily, weekly, or custom frequency (recurring task).

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Add the option to repeat a task, and a drop-down list to select the frequency in the UI. | 2 Hrs | Joanna |
| 2 | Display the repeated task in the task list. | 1 Hrs | Joanna |
| 3 | Build schema in Supabase to accommodate the feature’s need | 2 Hrs | Joanna |
| 4 | Develop backend logistics for recurrence | 4 Hrs | Joanna |
| 5 | Update the database to save repeated task information and include individual repeated tasks. | 4 Hrs | Joanna |
| 6 | Test manually | 2 Hrs | Joanna |

Acceptance criteria:

1. Given the parent is creating or editing a task, when they enable the “Repeat” option and select a frequency (daily, weekly, or custom) from the dropdown, then the UI displays the selected recurrence settings and allows the parent to save the task with those settings.  
2. Given a recurring task is saved successfully, when the system writes to Supabase, then the database stores the recurrence rule/settings for the task and links it to the correct parent  
3. Given a task has a valid recurrence rule, when the task list is loaded, then the task list displays the recurring task and includes the individual occurrences that fall within a certain time range according to the saved recurrence settings.  
4. Given the parent updates or turns off recurrence for an existing task, when they save the changes, then the database and task list update so future occurrences reflect the new settings and previously generated occurrences are handled consistently (updated or removed) without duplicates.

---

**User Story \#2-4**  
As a parent, I would like to set a task as a one-off, non-recurring task.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Accommodate the option in the recurrence UI | 1 Hrs | Joanna |
| 2 | Implement the database so a task can be set as recurrence task or non-recurrence task | 2 Hrs | Joanna |
| 3 | Create an logistics that save inputted information into database | 1 Hrs | Joanna |
| 4 | Test: debug and test functionalities with manual testing (checking database reflect) | 1 Hrs | Joanna |

Acceptance criteria:

1. Given the parent saves a task as one off with valid required fields, when they click “Save,” then the system creates or updates the task successfully and shows confirmation in the UI.  
2. Given the task is saved as one off, when the system writes to the database, then the task record is stored with a clear indicator that it is non-recurring and no recurrence rule data is stored for that task.  
3. Given a one off task is created, when the task list is loaded, then the task appears as a single task instance and does not generate additional future occurrences.

---

**User Story \#2-6**  
As a parent, I would like to assign a task to multiple children simultaneously, letting each child have their individual version of the assigned task.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Update task creation, task list, and error message UI to enable multiple assignees | 3 Hrs | Joanna |
| 2 | Develop backend logistics for creating separate tasks for each assigned child and save to the database | 3 Hrs | Joanna |
| 3 | Test: debug and test functionalities with manual testing (checking if the database reflect) | 2 Hrs | Joanna |

Acceptance criteria:

1. Given the parent is creating or editing a task and has multiple linked children, when they open the assignee selector, then the UI allows selecting multiple children and clearly shows which children are selected.  
2. Given the parent selects more than one child and clicks “Save,” when the request is processed, then the system creates a separate child-specific task instance for each selected child (each with its own unique task record) using the same task details.  
3. Given the parent attempts to save a task with no children selected, when they click “Save,” then the system blocks submission and displays an error message indicating that at least one child must be selected.  
4. Given the parent returns to the task list after saving, when the task list loads or refreshes, then the UI displays the assigned tasks for each child in a way that makes it clear each child has their own version.
---
**User Story \#2-7**  
As a parent, I would like to specify the type of resource (e.g., Water, Food, Hygiene) as a reward.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Create UI for the resource assignment | 2 Hrs | Joanna |
| 2 | Update the database to allow task information to have associated resources | 2 Hrs | Joanna |
| 3 | Develop backend logistics and connection to database | 3 Hrs | Joanna |
| 4 | Test: debug and test functionalities with manual testing (checking database reflect) | 1 Hrs | Joanna |

Acceptance criteria:

1. Given the parent is creating or editing a task and the reward section is visible, when they open the resource selector, then the UI displays available resource types (e.g., Water, Food, Hygiene) and allows the parent to from the resource types.  
2. Given the parent selects a resource type and saves the task, when the save completes, then the task displays the selected resource type in the task details.  
3. Given a task with a resource reward exists in the database, when the parent refreshes the page or reloads the task list, then the UI continues to show the correct resource type reward and matches what is stored in the database.
---
**User Story \#2-8**  
As a parent, I would like to specify the amount of the resource reward for task completion.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Create assign UI that allow the parent to assign specific amount of resources | 2 Hrs | Joanna |
| 2 | Develop backend logistics and connection to database | 2 Hrs | Joanna |
| 3 | Test: debug and test functionalities with manual testing | 1 Hrs | Joanna |

Acceptance criteria:

1. Given the parent is creating or editing a task, when they enter a numeric amount in the resource amount field and click “Save,” then the task is saved successfully and the reward amount is shown in the task details.  
2. Given the parent enters an invalid resource amount (non-numeric, negative, or empty when required), when they click “Save,” then the system blocks saving and displays a clear validation message.  
3. Given a task has a resource reward amount saved, when the parent reloads the page or revisits the task later, then the reward amount displayed matches what is stored in the database and does not revert.
---
**User Story \#2-14**  
As a parent, I would like to choose a task to assign from a list of preset tasks.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Create a list of common tasks. | 2 Hrs | Zoey |
| 2 | Design UI to choose from the preset. | 2 Hrs | Zoey |
| 3 | Test: debug and test functionalities with manual testing. | 2 Hrs | Zoey |

Acceptance criteria:

1. As a parent, I should be able to see a list of preset tasks when I am creating a task.  
2. Clicking on a preset task should auto-populate fields such as the name of the task.  
3. Parents should be able to assign a preset task to children, just like a self-made one.

## Task Viewing & Submission (Child):

**User Story \#3-1**  
As a child, I would like to view a list of all tasks currently assigned to me.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Create the task list UI and the entry page for child tasks | 3 Hrs | Taylor |
| 2 | Design the table schema in Supabase | 1 Hrs | Taylor |
| 3 | Create backend logic to fetch the data | 2 Hrs | Taylor |
| 4 | Integrate the UI and logic | 2 Hrs | Taylor |
| 5 | Test manually | 1 Hrs | Taylor |

Acceptance criteria:

1. Given the child navigates to the tasks page, I can see a list of tasks that are assigned to me.  
2. Given the refresh scroll, I can refresh the page to update the list of tasks.  
3. Given that the database schema in Supabase is designed correctly, each task assigned to the child should be properly stored and associated with the correct child account.
---
**User Story \#3-2**  
As a child, I would like the list of tasks to display the due date and remaining time.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Create the UI to show the due date and remaining time for each task on the list | 2 Hrs | Taylor |
| 2 | Modify the previous user story backend logic so it also gets the due date and remaining time for tasks | 1 Hrs | Taylor |
| 3 | Test manually | 1 Hrs | Taylor |

Acceptance criteria:

1. Given that the child is on the task page, I can see the due date for each task.  
2. For the tasks that are close to the deadline of the due date, it will be shown in red, which indicates it needs immediate action.  
3. Given that the due date exists for a task, the remaining time should be calculated and displayed accurately.  
4. Given that the UI and backend are integrated correctly, the due date and remaining time should load automatically when the task list page is opened.
---
**User Story \#3-3**  
As a child, I would like to select a task to view its full title, description, and required reward.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Create the UI to display specific information for a task | 3 Hrs | Taylor |
| 2 | Create the logic for fetching specific task information | 2 Hrs | Taylor |
| 3 | Integrate the UI and logic | 2 Hrs | Taylor |
| 4 | Test manually | 1 Hrs | Taylor |

Acceptance criteria:

1. Given that the child selects a task, a pop-up will show up.  
2. Given that the pop-up appears, it will display all the task information.  
3. Given that the task information is fetched correctly, I, as a child, should be able to see the exact same description that my parent entered for the task.
---
**User Story \#3-4**  
As a child, I would like to mark a task as complete to submit it for parent approval.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Modify the UI for the tasks list so the child can mark it as complete | 3 Hrs | Taylor |
| 2 | Create the logic for updating the task status | 2 Hrs | Taylor |
| 3 | Integrate the frontend and backend | 2 Hrs | Taylor |
| 4 | Test manually | 1 Hrs | Taylor |

Acceptance criteria:

1. Given the child on the tasks page, I can see the check box next to each task.  
2. Given that I, a child, marked the task as checked, the task status will change to pending.  
3. Given that a task is marked as complete, the task should be sent for parent approval and no longer appear as an active task.

## Task Approval & History (Parent & Child):

**User Story \#4-1**  
As a parent, I would like to view a dashboard listing all task submissions pending my approval.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Create pending list UI | 2 Hrs | Zoey |
| 2 | Build the table schema in Supabase | 2 Hrs | Zoey |
| 3 | Implement the background logistics of fetching the database and approval procedures | 4 Hrs | Zoey |
| 4 | Test manually | 2 Hrs | Zoey |

Acceptance criteria:

1. As a parent, I should be able to see a list of tasks pending my review.  
2. When a child submits a new review, the change should be reflected on my list and in the database.  
3. I should be able to tell the submissions from different children apart.  
4. Tasks that have already been rejected or accepted should not be shown on the pending list.
---
**User Story \#4-3**  
As a parent, I would like to approve a completed task submission.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Create UI for approval and ensure the pending list reflects real-time updates to the completion action | 3 Hrs | Zoey |
| 2 | Create backend logic and connect with the database for fetching and updating | 3 Hrs | Zoey |
| 3 | Test manually | 2 Hrs | Zoey |

Acceptance criteria:

1. After clicking on a task in the pending list, I, as a parent, should be able to see a page to reject or accept the task.  
2. A task should be removed from the pending list after it is accepted.  
3. The acceptance of a task should be reflected in the database.  
4. Given that the backend logic and database connection are implemented correctly, I, as a parent, should be able to approve a completed task submission.
---
**User Story \#4-4**  
As a parent, I would like to reject a completed task submission.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Create UI for approval and ensure the pending list reflects real-time updates to the reject action | 3 Hrs | Taylor |
| 2 | Create backend logic and connect with the database for fetching and updating | 3 Hrs | Taylor |
| 3 | Test manually | 2 Hrs | Taylor |

Acceptance criteria:

1. Given that the rejection UI is implemented correctly, I, as a parent, should be able to reject a completed task submission from the pending list.  
2. Given that the backend logic and database connection are implemented correctly, rejecting a task should update the task status to “rejected” in the database.  
3. Given that real-time updates are implemented correctly, the pending task list should immediately reflect the rejection action without requiring a manual page refresh.  
4. Given that a task submission is rejected, it should no longer appear in the pending approval list.
---
**User Story \#4-5**  
As a parent, I would like to enter text feedback when rejecting a task submission.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Add UI for the message | 1 Hrs | Taylor |
| 2 | Build schema in Supabase | 1 Hrs | Taylor |
| 3 | Create backend logic to fetch and update the data | 2 Hrs | Taylor |
| 5 | Test manually | 1 Hrs | Taylor |

Acceptance criteria:

1. Given that the rejection UI is implemented correctly, I, as a parent, should be able to enter text feedback when rejecting a task submission.  
2. Given that the Supabase schema is built correctly, the feedback message should be stored and associated with the correct task submission.  
3. Given that the backend logic is implemented correctly, submitting rejection feedback should update the task status to “rejected” in the database.  
4. Given that the frontend and backend are integrated correctly, the feedback message should be saved and reflected in the system after submission.  
5. Given that manual testing is completed, rejection feedback should correctly update the task status and store the message without affecting other task submissions.

## UI & Aesthetics:

**User Story \#6-1**  
The aesthetic throughout the app should be consistent. Such as the color scheme, background, and font.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Decide on the set of color schemes. | 2 Hrs | Zoey |
| 2 | Find suitable resources on the internet. Including backgrounds, fonts, and images. Determine whether or not, or how much, we have to draw on our own. | 3 Hrs | Zoey |
| 3 | Apply the backgrounds. | 3 Hrs | Zoey |
| 4 | Change the buttons. If we decide to use other packages or images instead of the original package, make sure all the functions are correctly connected. | 5 Hrs | Zoey |
| 5 | Test to see if all the changes are reflected. | 1 Hrs | Zoey |

Acceptance criteria:

1. Given that the color scheme is decided and applied correctly, the app should use a consistent set of primary and secondary colors across all pages.  
2. Given that backgrounds and fonts are selected and implemented correctly, all screens in the app should display the same background style and font family unless intentionally specified.  
3. Given that UI components such as buttons are updated, all buttons should follow a consistent style in terms of color, shape, size, and font.  
4. Given that external packages or images are used, all UI elements should function correctly and remain properly connected to their original features.  
5. Given that testing is completed, visual elements such as colors, fonts, backgrounds, and buttons should appear consistently across the entire application without layout or styling conflicts.
---
**User Story \#6-2**  
Create a logo for our app, and add it to the corresponding places.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Design a logo. | 2 Hrs | Zoey |
| 2 | Add the logo to the corresponding places. | 1 Hrs | Zoey |

Acceptance criteria:

1. Logos should be shown in all appropriate places throughout the app.  
2. Given that the logo design is finalized, the logo file should be exported in appropriate formats and resolutions for use in the app.  
3. Given that the logo is implemented in the UI, it should not distort, stretch, or overlap with other UI components.

## Gamification & Creature Care:

**User Story \#5-3**  
As a child, I would like to select a resource type to apply to my creature/environment.

| \# | Task Description | Estimated Time | Task Owner |
| :---: | ----- | :---: | :---: |
| 1 | Add ui for the resource application (being able to choose what resource, and animations for clarity) | 3 Hrs | William |
| 2 | Make it so that applying a resource will trigger a certain animation for the pet. | 5 Hrs | William |
| 3 | Make sure to allow when I can be applying the resource (e.g. when pet has max status or when resource runs out) | 3 Hrs | William |
| 4 | **Test**: Verify that applying the resource correctly updates the status bars, and also reflects in the database. | 3 Hrs | William |

Acceptance criteria:

1. Given that a resource is applied, the correct animation triggers.  
2. Given that a resource is applied, the resource is correctly reduced.  
3. Given that a resource is applied, there’s clear visual feedback as to which resource is applied.
---
**User Story \#5-5**

As a child, I would like to see visual feedback (e.g., an animated "sad" state) when the creature's status drops too low.

| \# | Task Description | Estimated Time | Task Owner |
| ----- | ----- | ----- | ----- |
| 1 | Define the logic and thresholds for various status-based state changes. | 4 Hrs | William |
| 2 | Develop the visual assets and animations representing "low" or "critical" status states. | 4 Hrs | William |
| 3 | Implement a system to monitor status levels and trigger the appropriate visual response. | 5 Hrs | William |
| 5 | Testing: Verify that visual states update correctly in response to status changes. | 3 Hrs | William |

Acceptance Criteria: 

1. Given a creature’s status level falls below a threshold, when viewed by the child, then the creature must display a clear visual change indicating its need.  
2. Given the creature is in a "needy" state, when resources are applied to raise levels above the threshold, then the creature must return to its normal visual state. 

---

**User Story \#5-8**

As a child, I would like to see available cosmetic items, unlock them, and place/edit their positions in the environment.

| \# | Task Description | Estimated Time | Task Owner |
| ----- | ----- | ----- | ----- |
| 1 | Configure the data structures and backend storage for cosmetic items and ownership tracking. | 2 Hrs | WIlliam |
| 2 | Design the interface for viewing, selecting, and distinguishing between owned and locked items. | 6 Hrs | William |
| 4 | Develop the functionality to position and arrange unlocked items within the game world. | 5 Hrs | William |
| 5 | Implement a system to persist the location and state of placed items in the database. | 4 Hrs | William |
| 6 | Testing: Ensure that item ownership and placement are correctly associated with individual accounts. | 3 Hrs | William |

Acceptance Criteria: 

1. Given the cosmetic interface is open, when a child browses items, then they must be able to clearly identify which items are currently available for use.  
2. Given a new item is unlocked, when the child checks the menu, then that item must be accessible for placement.  
3. Given an item has been positioned in the environment, when the application is restarted, then the item must remain in its saved location.  
   

## Current Total Hours: 176.5Hrs

| Name | Estimated Time |
| :---: | :---: |
| Taylor | 42 Hrs |
| William | 50 Hrs |
| Zoey | 43.5 Hrs |
| Joanna | 41 Hrs |

# Remaining Backlog

**User Account & Authentication:**

1. ~~As a parent, I would like to create a new parent account.~~  
2. ~~As a parent, I would like to securely log in using email and a password.~~  
3. ~~As a parent, I would like to securely log out of my account.~~  
4. ~~As a parent, I would like to reset my password if I forget it.~~  
5. ~~As a parent, I would like to manage/edit my parent profile.~~  
6. ~~As a parent, I would like to view a list of all linked child accounts.~~  
7. ~~As a parent, I would like to create a new child account for my child.~~  
8. As a parent, I would like to link a child's account to my parent profile.  
9. ~~As a child, I would like to securely log in using the same email as my parent account and a 6-digit code provided by my parents.~~

**Task Creation & Assignment (Parent):**

1. ~~As a parent, I would like to create a custom task with a unique title and detailed description.~~  
2. ~~As a parent, I would like to set a specific due date for a task.~~  
3. As a parent, I would like to set a task to repeat on a daily, weekly, or custom frequency (recurring task).  
4. As a parent, I would like to set a task as a one-off, non-recurring task.  
5. ~~As a parent, I would like to assign a task to a single child.~~  
6. As a parent, I would like to assign a task to multiple children simultaneously.  
7. As a parent, I would like to specify the type of resource (e.g., Water, Food, Hygiene) as a reward.  
8. As a parent, I would like to specify the amount of the resource reward for task completion.  
9. As a parent, I would like to be able to require photo evidence for a task to be marked as complete.  
10. ~~As a parent, I would like to edit the details of an existing task.~~  
11. ~~As a parent, I would like to delete an existing task.~~  
12. As a parent, I would like to create and name custom categories to organize tasks (e.g., "School," "Hygiene").  
13. ~~As a parent, I would like to view a list of all created and active tasks.~~  
14. As a parent, I would like to choose a task to assign from a list of preset tasks.

**Task Viewing & Submission (Child):**

1. As a child, I would like to view a list of all tasks currently assigned to me.  
2. As a child, I would like the list of tasks to display the due date.  
3. As a child, I would like to select a task to view its full title, description, and required reward.  
4. As a child, I would like to mark a task as complete to submit it for parent approval.  
5. As a child, I would like to take and upload a new photo as evidence for a required task.  
6. As a child, I would like to retake and upload a new photo if they don’t like it.  
7. As a child, I would like to receive a notification when a task is going to expire in an hour.

**Task Approval & History (Parent & Child):**

1. As a parent, I would like to view a dashboard listing all task submissions pending my approval.  
2. As a parent, I would like to view the submitted photo evidence for a task.  
3. As a parent, I would like to approve a completed task submission.  
4. As a parent, I would like to reject a completed task submission.  
5. As a parent, I would like to enter text feedback when rejecting a task submission.  
6. As a child, I would like to receive a notification when a task submission is approved.  
7. As a child, I would like to receive a notification, including parent feedback, when a task submission is rejected.  
8. As a parent/child, I would like to view a historical log of all tasks completed, missed, or rejected.  
9. As a parent, I would like to view a report showing the task completion rate for each child over the last week/month.  
10. As a parent, I would like to view simple statistics of task completions, figuring what task is complete/miss the most to adjust reward when assigning tasks.

**Gamification & Creature Care:**

1. ~~As a child, I would like to see my total accumulated amount for each resource type (Water, Food, Hygiene, etc).~~  
2. ~~As a child, I would like to access the game environment to view my virtual creature.~~  
3. As a child, I would like to select a resource type to apply to my creature/environment.  
4. As a child, I would like to see my creature's status (hygiene, hunger, hydration) slowly deplete over time.  
5. As a child, I would like to see visual feedback (e.g., an animated "sad" state) when the creature's status drops too low.  
6. As a child, I would like to be able to open a mystery box (cosmetic items, resources, etc) under certain conditions.  
7. As a parent, I would like to view my child’s virtual creature and its current status levels.  
8. As a child, I would like to see available cosmetic items, unlock them, and place/edit their positions in the environment.

**UI & Aesthetics:**

1. The aesthetic throughout the app should be consistent. Such as the color scheme, background, and font.  
2. Create a logo for our app, and add it to the corresponding places.  
3. Create a dark mode for the app.