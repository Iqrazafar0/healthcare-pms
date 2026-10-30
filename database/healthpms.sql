CREATE DATABASE IF NOT EXISTS healthpms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE healthpms;
SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS quality_checks, defects, risks, activities, wbs_items, change_requests, requirements, team_members, projects;
SET FOREIGN_KEY_CHECKS=1;

CREATE TABLE projects (
 id INT AUTO_INCREMENT PRIMARY KEY, project_name VARCHAR(180) NOT NULL,
 client_name VARCHAR(180) NOT NULL, objectives TEXT, stakeholders TEXT,
 scope_inclusions TEXT, scope_exclusions TEXT, approved_budget DECIMAL(14,2) NOT NULL DEFAULT 5000000,
 baseline_weeks INT NOT NULL DEFAULT 16, start_date DATE, deadline DATE,
 status ENUM('In Progress','On Hold','Completed','Cancelled') DEFAULT 'In Progress',
 quality_plan TEXT, closure_notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE team_members (
 id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(120) NOT NULL, role VARCHAR(120) NOT NULL,
 email VARCHAR(180), allocation_percent DECIMAL(5,2) DEFAULT 100,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE requirements (
 id INT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(220) NOT NULL, description TEXT,
 priority ENUM('High','Medium','Low') DEFAULT 'Medium',
 status ENUM('Proposed','Approved','Rejected') DEFAULT 'Proposed',
 category VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE wbs_items (
 id INT AUTO_INCREMENT PRIMARY KEY, wbs_code VARCHAR(30) NOT NULL, deliverable VARCHAR(220) NOT NULL,
 work_package VARCHAR(220), parent_id INT NULL, owner VARCHAR(120),
 status ENUM('Not Started','In Progress','Completed','On Hold') DEFAULT 'Not Started',
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT fk_wbs_parent FOREIGN KEY(parent_id) REFERENCES wbs_items(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE change_requests (
 id INT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(220) NOT NULL, justification TEXT,
 cost_impact DECIMAL(14,2) NOT NULL DEFAULT 0, weeks_impact INT NOT NULL DEFAULT 0,
 status ENUM('Pending','Approved','Rejected') DEFAULT 'Pending',
 approved_by VARCHAR(120), applied TINYINT(1) NOT NULL DEFAULT 0,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE activities (
 id INT AUTO_INCREMENT PRIMARY KEY, wbs_id INT NULL, title VARCHAR(220) NOT NULL, description TEXT,
 assignee_id INT NULL, assignee_name VARCHAR(120), start_date DATE, end_date DATE, duration_days INT DEFAULT 1,
 dependency_ids VARCHAR(255), budgeted_cost DECIMAL(14,2) DEFAULT 0, actual_cost DECIMAL(14,2) DEFAULT 0,
 progress DECIMAL(5,2) DEFAULT 0,
 status ENUM('Not Started','In Progress','Delayed','Completed') DEFAULT 'Not Started',
 is_milestone TINYINT(1) DEFAULT 0,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT fk_activity_wbs FOREIGN KEY(wbs_id) REFERENCES wbs_items(id) ON DELETE SET NULL,
 CONSTRAINT fk_activity_assignee FOREIGN KEY(assignee_id) REFERENCES team_members(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE defects (
 id INT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(220) NOT NULL, description TEXT,
 severity ENUM('Critical','High','Medium','Low') DEFAULT 'Medium',
 module VARCHAR(120), assigned_to VARCHAR(120),
 status ENUM('Open','In Progress','Resolved') DEFAULT 'Open',
 reported_date DATE, resolved_date DATE,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE quality_checks (
 id INT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(220) NOT NULL, deliverable VARCHAR(160),
 result ENUM('Not Tested','Pass','Fail') DEFAULT 'Not Tested',
 inspector VARCHAR(120), inspection_date DATE, notes TEXT,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE risks (
 id INT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(220) NOT NULL, description TEXT,
 likelihood TINYINT NOT NULL DEFAULT 1, impact TINYINT NOT NULL DEFAULT 1,
 response_action TEXT, owner VARCHAR(120),
 status ENUM('Open','Mitigated','Closed') DEFAULT 'Open',
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO projects(project_name,client_name,objectives,stakeholders,scope_inclusions,scope_exclusions,approved_budget,baseline_weeks,start_date,deadline,status,quality_plan)
VALUES('Smart Healthcare Project Management System','Network of Five Hospitals',
'Deliver an integrated healthcare platform for five hospitals covering patient appointments, laboratory reports, doctor schedules, online consultations and hospital billing.',
'Hospital management, patients, doctors, laboratory staff, finance teams, project manager, two backend developers, two frontend developers, database developer and QA engineer.',
'Patient appointment scheduling; laboratory reports; doctor schedules; online consultations; hospital billing; validation; integration and reporting.',
'AI preliminary diagnosis and mobile application are excluded from the original baseline until formal change approval.',
5000000,16,'2026-10-26','2027-02-15','In Progress',
'Peer review, functional testing, integration testing, regression testing, security checks and user acceptance testing.');

INSERT INTO team_members(name,role,email,allocation_percent) VALUES
('Project Manager','Project Manager','pm@healthpms.local',100),
('Backend Developer 1','Backend Developer','backend1@healthpms.local',100),
('Backend Developer 2','Backend Developer','backend2@healthpms.local',100),
('Frontend Developer 1','Frontend Developer','frontend1@healthpms.local',100),
('Frontend Developer 2','Frontend Developer','frontend2@healthpms.local',100),
('Database Developer','Database Developer','database@healthpms.local',100),
('QA Engineer','Quality Assurance Engineer','qa@healthpms.local',100);

INSERT INTO requirements(title,description,priority,status,category) VALUES
('Patient appointment scheduling','Book, reschedule and cancel appointments across five hospitals.','High','Approved','Functional'),
('Laboratory reports management','Upload, review and make lab reports available to authorized users.','High','Approved','Functional'),
('Doctor schedules and availability','Manage doctors, working hours and appointment slots.','High','Approved','Functional'),
('Online consultations','Support remote consultations and consultation records.','Medium','Approved','Functional'),
('Hospital billing','Generate invoices and track billing/payment status.','High','Approved','Functional');

INSERT INTO wbs_items(wbs_code,deliverable,work_package,owner,status) VALUES
('1.0','Project initiation','Charter, stakeholders and project plan','Project Manager','Completed'),
('2.0','Scope management','Requirements register and approved WBS','Project Manager','In Progress'),
('3.0','Schedule and resources','Activities, dependencies and team assignments','Project Manager','In Progress'),
('4.0','Cost management','Budget estimates and EVM reporting','Database Developer','In Progress'),
('5.0','Quality and risk','Defect tracking, test checklist and risk responses','QA Engineer','In Progress'),
('6.0','Integration and reporting','System integration, validation and reports','Development Team','Not Started');

INSERT INTO change_requests(title,justification,cost_impact,weeks_impact,status,approved_by,applied) VALUES
('AI-based preliminary diagnosis module','Hospital management requests AI-assisted preliminary assessment.',500000,2,'Pending',NULL,0),
('Mobile application','Provide mobile access for patients and hospital staff.',300000,1,'Pending',NULL,0);

INSERT INTO activities(title,description,assignee_name,start_date,end_date,duration_days,dependency_ids,budgeted_cost,actual_cost,progress,status,is_milestone) VALUES
('Requirements elicitation and project charter','Collect hospital requirements and approve project charter.','Project Manager','2026-10-26','2026-11-02',7,'',350000,340000,100,'Completed',1),
('Database design and integration','Design relational schema and database access layer.','Database Developer','2026-11-03','2026-11-18',15,'1',700000,470000,65,'In Progress',0),
('Appointment scheduling module','Implement booking, cancellation and slot validation.','Backend Developer 1','2026-11-10','2026-11-28',18,'1,2',650000,390000,45,'Delayed',0),
('Patient record management','Implement patient profiles and protected medical records.','Backend Developer 2','2026-11-12','2026-11-30',18,'1,2',600000,350000,55,'In Progress',0),
('Frontend dashboards and workflows','Build responsive hospital staff and patient workflows.','Frontend Developers (2)','2026-11-15','2026-12-05',20,'2',850000,300000,35,'In Progress',0),
('Quality assurance and validation','Execute integration, regression and acceptance testing.','QA Engineer','2026-12-01','2026-12-12',11,'3,4,5',450000,45000,10,'Not Started',0);

INSERT INTO defects(title,description,severity,module,assigned_to,status,reported_date) VALUES
('Appointment slot double-booking under concurrent requests','Two patients can reserve the same doctor slot under concurrent requests.','Critical','Appointment scheduling','Backend Developer 1','Open','2026-11-20'),
('Patient record update does not preserve audit fields','Some updates overwrite audit metadata in patient records.','Critical','Patient record management','Backend Developer 2','In Progress','2026-11-21');

INSERT INTO quality_checks(title,deliverable,result,inspector,inspection_date,notes) VALUES
('Appointment booking prevents overlapping doctor slots','Appointment module','Fail','QA Engineer','2026-11-22','Concurrency regression test failed.'),
('Patient record access is role-restricted','Patient records','Not Tested','QA Engineer',NULL,'Verify authorization for each role.'),
('Billing totals match approved charges','Billing module','Not Tested','QA Engineer',NULL,'Validate rounding and totals.');

INSERT INTO risks(title,description,likelihood,impact,response_action,owner,status) VALUES
('Appointment scheduling defects delay integration testing','Critical booking defects may block integrated test execution.',5,5,'Add concurrency tests, make slot booking atomic, and run regression tests before release.','Backend Developer 1','Open'),
('Patient record integrity issue','Audit data may be lost during patient record updates.',4,5,'Add transaction-safe updates, audit validation and backup/restore tests.','Backend Developer 2','Open'),
('Change requests exceed baseline budget and deadline','AI and mobile scope requests add cost and schedule.',4,4,'Keep changes outside baseline until formal approval; update budget and schedule only after approval.','Project Manager','Open');
