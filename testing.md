# APPENDICES

# APPENDIX A. DETAILED SYSTEM TESTING SCENARIOS

This appendix presents the detailed testing scenarios for evaluating the MEDITRACE system. Testing is divided into three packages: medication monitoring, BLE separation alerts, and system disturbance and recovery.

## A.1. Testing Package A – Medication Monitoring

Testing Package A evaluates the ability of MEDITRACE to detect medication-related activities, record events, classify medication retrieval times, and provide refill reminders.

| Session | Test ID | Testing Scenario | Expected Result |
|---|---|---|---|
| 1 | A1.1 | Place medication in compartment 1 and observe the IR sensor response. | The system detects medication presence. |
| 1 | A1.2 | Remove medication from compartment 1. | The system detects the change in medication presence. |
| 1 | A1.3 | Operate the compartment limit switch. | The system records the corresponding compartment state change. |
| 1 | A1.4 | Repeat the detection procedure for compartments 2–5. | Each compartment is detected independently. |
| 2 | A2.1 | Perform medication retrieval before the scheduled time. | The application classifies the event as early. |
| 2 | A2.2 | Perform medication retrieval within the scheduled time window. | The application classifies the event as on-time. |
| 2 | A2.3 | Perform medication retrieval after the scheduled time window. | The application classifies the event as late. |
| 2 | A2.4 | Do not perform medication retrieval within the defined observation period. | The application classifies the dose as missed. |
| 3 | A3.1 | Perform a medication retrieval event and check the application history. | The event is recorded with the corresponding timestamp. |
| 3 | A3.2 | Perform multiple retrieval events. | Each event is recorded without unintended duplication. |
| 4 | A4.1 | Leave a compartment empty before the scheduled refill reminder. | The application identifies the compartment as requiring a refill. |
| 4 | A4.2 | Trigger the morning refill reminder. | The application displays a reminder for the empty compartment. |
| 4 | A4.3 | Refill the empty compartment. | The compartment status is updated according to sensor detection. |
| 5 | A5.1 | Repeat medication presence and retrieval tests across all five compartments. | The system consistently detects and records the tested events. |
| 5 | A5.2 | Compare recorded events with direct observations. | The recorded results correspond to the observed test activities. |

**Note:** The number of interactions and repetitions should be finalized in the testing protocol. The table above describes test cases, not the number of independent test sessions.

## A.2. Testing Package B – BLE Separation Alert

Testing Package B evaluates BLE connection monitoring and the notification process when the MEDBOX device becomes disconnected from the patient's smartphone.

| Session | Test ID | Testing Scenario | Expected Result |
|---|---|---|---|
| 1 | B1.1 | Connect MEDBOX to the patient's smartphone through BLE. | The application displays the connected status. |
| 1 | B1.2 | Disconnect the BLE connection. | The application detects the connection interruption. |
| 1 | B1.3 | Maintain the disconnection until the initial alert threshold. | The patient receives a separation warning. |
| 2 | B2.1 | Reconnect MEDBOX before the caregiver escalation threshold. | The application updates the connection status and follows the defined alert cancellation procedure. |
| 2 | B2.2 | Maintain the disconnection beyond the escalation threshold without patient acknowledgment. | The system initiates the caregiver escalation process. |
| 2 | B2.3 | Check the caregiver notification status. | The notification outcome is recorded. |
| 3 | B3.1 | Repeat the disconnection and reconnection process. | The system consistently detects the connection-state changes. |
| 3 | B3.2 | Perform the test with different disconnection durations. | The alert behavior follows the predefined time thresholds. |

**Note:** BLE disconnection indicates a possible separation between the patient and MEDBOX. It does not independently confirm that the patient has left the device behind. Caregiver notification requires an available communication pathway through the smartphone and the configured internet or backend service.

## A.3. Testing Package C – System Disturbance and Recovery

Testing Package C evaluates system behavior during connectivity interruptions and operational disturbances.

| Session | Test ID | Testing Scenario | Expected Result |
|---|---|---|---|
| 1 | C1.1 | Interrupt the BLE connection during normal operation. | The system identifies the connection interruption. |
| 1 | C1.2 | Restore the BLE connection. | The application can reconnect to MEDBOX. |
| 2 | C2.1 | Restart the smartphone application. | The application resumes operation and retrieves available device information. |
| 2 | C2.2 | Restart the MEDBOX device. | The device initializes and resumes its programmed functions. |
| 3 | C3.1 | Perform a medication-related activity during or after a connectivity interruption. | The system handles the event according to its defined data-storage and synchronization mechanism. |
| 3 | C3.2 | Check the application history after recovery. | Available records remain consistent with the system's data-handling design. |

**Note:** Tests involving power interruption, event buffering, and data synchronization should only be included if those functions have been implemented.

---

# APPENDIX B. TESTING INSTRUMENTS AND OBSERVATION SHEETS

This appendix contains the instruments used to record the results of system testing.

## B.1. General Testing Record

| Field | Description |
|---|---|
| Test ID | Identification code of the test case |
| Date | Date of testing |
| Session | Testing session number |
| Device ID | Identification of the MEDBOX device |
| Tester | Person conducting the test |
| Initial Condition | Device and application conditions before testing |
| Test Procedure | Activity performed during testing |
| Expected Result | Expected system response |
| Actual Result | Observed system response |
| Test Status | Pass / Fail |
| Remarks | Additional observations |

## B.2. Medication Monitoring Observation Sheet

| No. | Compartment | Medication Present | Limit Switch Response | IR Sensor Response | Application Record | Result |
|---|---|---|---|---|---|---|
| 1 | 1 | | | | | |
| 2 | 2 | | | | | |
| 3 | 3 | | | | | |
| 4 | 4 | | | | | |
| 5 | 5 | | | | | |

## B.3. Medication Retrieval Classification Record

| No. | Test ID | Scheduled Time | Retrieval Time | Expected Classification | Actual Classification | Result |
|---|---|---|---|---|---|---|
| 1 | | | | Early | | |
| 2 | | | | On-time | | |
| 3 | | | | Late | | |
| 4 | | | | Missed | | |

## B.4. BLE Separation Alert Observation Sheet

| No. | Test ID | Disconnection Time | Patient Alert Time | Caregiver Alert Time | Reconnection Time | Result |
|---|---|---|---|---|---|---|
| 1 | | | | | | |
| 2 | | | | | | |
| 3 | | | | | | |

## B.5. System Recovery Observation Sheet

| No. | Test ID | Disturbance Type | Initial Condition | Recovery Action | System Response | Result |
|---|---|---|---|---|---|---|
| 1 | | BLE interruption | | | | |
| 2 | | Application restart | | | | |
| 3 | | Device restart | | | | |
| 4 | | Other disturbance | | | | |

---

# APPENDIX C. OPERATIONAL DEFINITIONS AND TESTING CRITERIA

This appendix defines the operational parameters used to interpret system behavior and determine testing outcomes.

## C.1. Medication Detection

| Parameter | Operational Definition | Expected Condition |
|---|---|---|
| Medication presence | The condition detected by the IR reflection sensor when medication is present in a compartment. | The sensor output corresponds to the medication presence condition established during calibration. |
| Medication absence | The condition detected when medication is removed from a compartment. | The sensor output changes according to the calibrated absence condition. |
| Compartment state | The state detected through the corresponding limit switch. | The application or device records the intended switch-state change. |
| Retrieval event | A medication-related event identified from the configured sensor-state changes. | The event is recorded according to the programmed event logic. |

**Important:** Medication retrieval is treated as a monitored medication-related activity. Sensor detection alone does not verify that the medication has been swallowed.

## C.2. Medication Time Classification

The application classifies medication retrieval events based on the difference between the scheduled medication time and the detected retrieval time.

| Classification | Operational Definition | Time Boundary |
|---|---|---|
| Early | Retrieval occurs before the scheduled time. | Before the scheduled minute |
| On-time | Retrieval occurs at or after the scheduled time and within the late tolerance. | 0–15 minutes after schedule |
| Late | Retrieval occurs after the late tolerance but before the missed-dose threshold. | More than 15 minutes and up to 120 minutes after schedule |
| Missed | No qualifying retrieval event occurs before the missed-dose threshold. | More than 120 minutes after schedule |

The time boundaries must be defined before testing and applied consistently throughout the evaluation.

## C.3. BLE Separation Alert Parameters

| Parameter | Operational Definition | Proposed Threshold |
|---|---|---|
| BLE disconnection detection | Detection of an interrupted BLE connection between MEDBOX and the smartphone. | Based on the application/device connection-state mechanism. |
| Patient warning | Warning displayed after the application detects an unacknowledged disconnection. | 30 seconds after detection |
| Caregiver escalation | Caregiver notification initiated when disconnection persists without patient acknowledgment. | 5 minutes after patient warning (about 5 minutes 30 seconds after detection) |
| Reconnection | Restoration of the BLE connection. | Detected by the application/device. |

The caregiver escalation condition must specify whether the five-minute period is measured from the initial disconnection or from the patient warning. The acknowledgment mechanism and the effect of reconnection on pending notifications must also be defined.

## C.4. Testing Outcome Criteria

| Test Outcome | Definition |
|---|---|
| Pass | The actual system response meets the predefined expected result. |
| Fail | The actual system response does not meet the predefined expected result. |
| Not Tested | The test case has not been executed. |
| Invalid Test | The test cannot be evaluated because the initial conditions or test procedure were not properly established. |

## C.5. Performance Indicators

| Indicator | Measurement |
|---|---|
| Medication detection success rate | Number of successful detection tests divided by total valid detection tests × 100%. |
| Classification success rate | Number of correctly classified test events divided by total valid classification tests × 100%. |
| Notification delivery success rate | Number of successfully delivered notifications divided by total valid notification tests × 100%. |
| BLE detection response time | Time between the actual connection interruption and its detection by the application/device. |
| System recovery success rate | Number of successful recovery tests divided by total valid recovery tests × 100%. |

---

# APPENDIX D. SYSTEM TECHNICAL DOCUMENTATION

This appendix presents the technical documentation supporting the implementation and evaluation of MEDITRACE.

## D.1. Hardware Components

| Component | Quantity | Function |
|---|---:|---|
| ESP32-C3 Super Mini | 1 | Main microcontroller and BLE communication |
| PCF8575 | 1 | I/O expansion for sensor and switch connections |
| IR reflection sensor | 5 | Detects medication presence in each compartment |
| Limit switch | 5 | Detects the corresponding compartment state |
| Active buzzer | 1 | Provides audible alerts |
| LiPo battery | 1 | Supplies portable power |
| MEDBOX enclosure | 1 | Houses the electronic components and medication compartments |

## D.2. Sensor Arrangement

Each of the five compartments is equipped with two sensing components:

| Compartment | IR Sensor | Limit Switch |
|---|---|---|
| 1 | IR 1 | Limit Switch 1 |
| 2 | IR 2 | Limit Switch 2 |
| 3 | IR 3 | Limit Switch 3 |
| 4 | IR 4 | Limit Switch 4 |
| 5 | IR 5 | Limit Switch 5 |

The IR sensors monitor medication presence, while the limit switches monitor the configured compartment state. The ESP32-C3 processes the input data and coordinates the system response.

## D.3. System Communication Architecture

The communication process is divided into two main connections:

1. **MEDBOX to Smartphone:** The ESP32-C3 communicates with the Flutter application through Bluetooth Low Energy (BLE).
2. **Smartphone to Caregiver:** Caregiver notifications are delivered through the configured smartphone internet and backend communication pathway.

BLE provides local communication between MEDBOX and the patient's smartphone. It does not independently provide remote internet communication.

## D.4. Medication Monitoring Process

1. Medication is placed in one of the five compartments.
2. The corresponding IR sensor detects the medication presence condition.
3. The ESP32-C3 processes the sensor input.
4. The system communicates relevant device information to the smartphone application through BLE.
5. When medication-related activity is detected, the application records the event according to the configured logic.
6. The application compares the event timestamp with the medication schedule.
7. The event is classified as early, on-time, or late. If no qualifying event occurs before the defined threshold, the dose is classified as missed.

## D.5. BLE Separation Alert Process

1. MEDBOX is connected to the patient's smartphone through BLE.
2. The application monitors the BLE connection status.
3. If the connection is interrupted, the system begins the configured disconnection timer.
4. After 30 seconds of continuous disconnection detected by the application, the patient receives a warning.
5. If the disconnection persists for the defined escalation period and the patient has not acknowledged the warning, the caregiver notification process is initiated.
6. The application records the relevant connection and notification events.
7. If the BLE connection is restored, the system updates its connection status and follows the predefined alert-handling procedure.

## D.6. Technical Diagrams

The following diagrams should be inserted into this appendix:

- Figure D.1. MEDITRACE hardware wiring diagram.
- Figure D.2. Five-compartment sensor arrangement.
- Figure D.3. MEDITRACE system communication architecture.
- Figure D.4. Medication monitoring flowchart.
- Figure D.5. BLE separation alert and caregiver escalation flowchart.

*Insert the finalized circuit diagram, sensor pin mapping, and application communication flow after hardware and software integration has been verified.*