//
//  CalendarViewController.swift
//  Recipe App
//
//  Created by Alex Tang on 11/13/24.
//

import UIKit
import FSCalendar
import EventKit
import EventKitUI

class CalendarViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource, UITableViewDelegate, UITableViewDataSource, EKEventEditViewDelegate {
    
    @IBOutlet weak var calendarContainerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var selectedRecipe: Recipe?
    var calendar: FSCalendar!
    let eventStore = EKEventStore()
    var events: [EKEvent] = []
    var selectedDate: Date?
    var emojiForDate: [Date: String] = [:]


    override func viewDidLoad() {
        super.viewDidLoad()
        setupCalendar()
        setupTableView()
        requestCalendarAccess()
            
        if let recipe = selectedRecipe {
            print("Received recipe: \(recipe.label)")
        }
    }
    
    
    /*
        CALENDAR SETUP: calendarContainerView and tableView (for daily events)
     */

    private func setupCalendar() {

        calendar = FSCalendar()
        calendar.translatesAutoresizingMaskIntoConstraints = false
        
        // Customize calendar appearance
        calendar.appearance.todayColor = .clear
        calendar.appearance.titleTodayColor = .systemRed
        calendar.appearance.titleFont = UIFont(name: "PingFangHK-Regular", size: 16)
        calendar.appearance.weekdayFont = UIFont(name: "PingFangHK-Regular", size: 14)
        calendar.appearance.headerTitleFont = UIFont(name: "PingFangHK-Regular", size: 18)

        // Add the calendar to the container view
        calendarContainerView.addSubview(calendar)

        NSLayoutConstraint.activate([
            calendar.topAnchor.constraint(equalTo: calendarContainerView.topAnchor),
            calendar.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor),
            calendar.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor),
            calendar.bottomAnchor.constraint(equalTo: calendarContainerView.bottomAnchor)
        ])

        calendar.delegate = self
        calendar.dataSource = self
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "eventCell")
        fetchEventsForSelectedDate()
    }
    
    
    /*
        FETCH USER CALENDAR DATA: Fetches calendars and daily events
     
            TO DO:
     */

    private func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    self.fetchEventsForSelectedDate()
                    self.fetchCookingScheduleEvents()
                    self.calendar.reloadData()
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Access to calendar was denied. Please enable it in Settings.")
                }
            }
        }
    }
    
    private func fetchEventsForSelectedDate() {
        guard let date = selectedDate else { return }

        // Get the start and end of the selected day
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)

        let allEvents = eventStore.events(matching: predicate) // for filtering out all day events
        events = allEvents.filter { !$0.isAllDay && Calendar.current.isDate($0.startDate, inSameDayAs: date) }

        if events.isEmpty {
                displayNoEventsMessage() // if there are no events for that day, display messafe
            } else {
                tableView.backgroundView = nil
                tableView.separatorStyle = .singleLine
            }

        tableView.reloadData()
    }
    
    
    /*
        COOKING SCHEDULE" CALENDAR : Creates, updates, and fetches events in "Cooking Schedule" calendar
     
            TO DO:
     */
    
    private func CookingScheduleCalendar() -> EKCalendar? {
        if let existingCalendar = eventStore.calendars(for: .event).first(where: { $0.title == "Potluck" }) {
            return existingCalendar
        }

        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = "Potluck"

        // Set the calendar source
        if let iCloudSource = eventStore.sources.first(where: { $0.sourceType == .calDAV }) {
            newCalendar.source = iCloudSource
        } else if let exchangeSource = eventStore.sources.first(where: { $0.sourceType == .exchange }) {
            newCalendar.source = exchangeSource
        } else {
            // Fallback to a local calendar source
            if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
                newCalendar.source = localSource
            } else {
                showAlert(title: "Error", message: "No suitable calendar source found.")
                return nil
            }
        }

        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            return newCalendar
        } catch {
            showAlert(title: "Error", message: "Failed to create 'Potluck' calendar: \(error.localizedDescription)")
            return nil
        }
    }

    private func createCalendarEvent(for recipe: Recipe, startTime: Date) -> EKEvent? {
        guard let cookingCalendar = CookingScheduleCalendar() else { return nil }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = recipe.label
        event.calendar = cookingCalendar
        event.url = URL(string: recipe.url)
        event.notes = """
        Recipe: \(recipe.label)
        Cook Time: \(recipe.totalTime) minutes
        
        Ingredients:
        \(recipe.ingredientLines.joined(separator: "\n"))
        """
        
        event.startDate = startTime
        let duration = recipe.totalTime > 0 ? recipe.totalTime : 60
        event.endDate = Calendar.current.date(byAdding: .minute, value: duration, to: startTime)!
        
        return event
    }
    
    private func fetchCookingScheduleEvents() {
        guard let cookingCalendar = eventStore.calendars(for: .event).first(where: { $0.title == "Potluck" }) else { return }

        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [cookingCalendar])

        let allEvents = eventStore.events(matching: predicate)
        emojiForDate = [:] // Clear previous emojis

        // Iterate through all events and mark dates with the emoji
        for event in allEvents {
            let date = Calendar.current.startOfDay(for: event.startDate)
            emojiForDate[date] = "🍴" // Set the spoon and fork emoji for each date
        }

        calendar.reloadData() // Refresh the calendar to reflect changes
    }


    private func displayNoEventsMessage() {
        let noEventsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        noEventsLabel.text = "No events for this day"
        noEventsLabel.textColor = .gray
        noEventsLabel.textAlignment = .center
        noEventsLabel.font = UIFont.systemFont(ofSize: 16)
        noEventsLabel.numberOfLines = 0

        tableView.backgroundView = noEventsLabel
        tableView.separatorStyle = .none
    }

    
    // MARK: - FSCalendarDelegate

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        selectedDate = date
        fetchEventsForSelectedDate()
    }
    
    func calendar(_ calendar: FSCalendar, titleFor date: Date) -> String? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return emojiForDate[startOfDay] // Returns "🍴" if the date has a Potluck event
    }
    
    private func startOfDay(for date: Date) -> Date {
        return Calendar.current.startOfDay(for: date)
    }
    
    // MARK: - FSCalendarDataSource

    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        // how a dot for each day that has events
        return events.filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) }.count
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath)
        let event = events[indexPath.row]

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let startTime = formatter.string(from: event.startDate)
        let endTime = formatter.string(from: event.endDate)
        cell.textLabel?.text = "\(startTime) - \(endTime): \(event.title ?? "No Title")"

        return cell
    }

    // MARK: - Event Creation
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        guard let selectedDate = selectedDate else {
            showAlert(title: "Error", message: "Please select a date.")
            return
        }

        guard let recipe = selectedRecipe else {
            showAlert(title: "Error", message: "No recipe selected.")
            return
        }

        findAndScheduleRecipe(recipe: recipe, on: selectedDate)
        
        fetchEventsForSelectedDate()
        tableView.reloadData()
    }

    
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        defer {
            // Dismiss the EKEventEditViewController
            controller.dismiss(animated: true, completion: nil)
        }
        

        switch action {
        case .canceled:
            print("Event editing was canceled.")
        case .saved:
            print("Event was saved.")
            fetchEventsForSelectedDate() // Refresh the list of events
            tableView.reloadData()
        case .deleted:
            print("Event was deleted.")
            fetchEventsForSelectedDate() // Refresh the list of events
            tableView.reloadData()
        @unknown default:
            break
        }
    }


    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func findAndScheduleRecipe(recipe: Recipe, on date: Date) {
        let calendar = Calendar.current
        let mealTimeRanges: [String: (startHour: Int, endHour: Int)] = [
            "breakfast": (6, 10),
            "lunch": (11, 15),
            "dinner": (17, 21),
            "snack": (14, 17),
            "teatime": (15, 17)
        ]

        let mealType = recipe.mealType?.first?.lowercased() ?? "dinner"
        let timeRange = mealTimeRanges[mealType] ?? (17, 21)

        let rangeStart = calendar.date(bySettingHour: timeRange.startHour, minute: 0, second: 0, of: date)!
        let rangeEnd = calendar.date(bySettingHour: timeRange.endHour, minute: 0, second: 0, of: date)!

        let duration = TimeInterval(recipe.totalTime > 0 ? recipe.totalTime : 60) * 60
        var availableSlots: [Date] = []
        var currentTime = rangeStart

        while currentTime < rangeEnd {
            let potentialEndTime = calendar.date(byAdding: .second, value: Int(duration), to: currentTime)!
            if potentialEndTime > rangeEnd { break }

            let hasConflict = events.contains { event in
                currentTime < event.endDate && potentialEndTime > event.startDate
            }

            if !hasConflict {
                availableSlots.append(currentTime)
            }

            currentTime = calendar.date(byAdding: .minute, value: 30, to: currentTime)!
        }

        if let selectedTime = availableSlots.randomElement() {
            if let event = createCalendarEvent(for: recipe, startTime: selectedTime) {
                try? eventStore.save(event, span: .thisEvent)
                
                // Refresh events and emojis for the calendar
                fetchCookingScheduleEvents()

                // Show success message
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                let alert = UIAlertController(
                    title: "Recipe Scheduled",
                    message: "Added \(recipe.label) to your calendar at \(formatter.string(from: selectedTime))",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        } else {
            let alert = UIAlertController(
                title: "No Available Time",
                message: "Could not find an available time slot for this meal. Please try another date.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}
