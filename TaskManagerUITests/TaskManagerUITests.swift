import XCTest

final class TaskManagerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// メモリ上の保存先・利用時間の制限 OFF で起動し、端末のデータや実行時刻に左右されないようにする
    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
        return app
    }

    /// 起動直後はタブバーの描画が間に合わないことがあるため、表示を待ってから押す
    @MainActor
    private func tapTab(_ title: String, in app: XCUIApplication) {
        let button = app.tabBars.buttons[title]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        button.tap()
    }

    @MainActor
    func testTabsSwitchBetweenScreens() throws {
        let app = launchApp()
        tapTab("タスク", in: app)
        XCTAssertTrue(app.staticTexts["taskListTitle"].waitForExistence(timeout: 5))

        tapTab("設定", in: app)
        XCTAssertTrue(app.staticTexts["settingsTitle"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCreatedTaskShowsInList() throws {
        let app = launchApp()
        tapTab("タスク", in: app)

        createTask("UI Test Task", in: app)
    }

    @MainActor
    func testTappingOutsideDismissesKeyboard() throws {
        let app = launchApp()
        tapTab("タスク", in: app)
        tapTab("作成", in: app)

        let field = app.textFields["editorTitleField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        tapAndWaitForKeyboard(field, in: app)

        app.navigationBars["タスクを追加"].staticTexts["タスクを追加"].tap()

        let keyboardGone = expectation(
            for: NSPredicate(format: "exists == false"), evaluatedWith: app.keyboards.element)
        wait(for: [keyboardGone], timeout: 5)
    }

    @MainActor
    func testTaskTabBecomesCreateButton() throws {
        let app = launchApp()
        tapTab("タスク", in: app)
        XCTAssertTrue(app.staticTexts["taskListTitle"].waitForExistence(timeout: 5))

        tapTab("作成", in: app)

        XCTAssertTrue(app.navigationBars["タスクを追加"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAddingCategoryWithColorShowsBadge() throws {
        let app = launchApp()
        tapTab("タスク", in: app)

        addCategory(named: "学校", colorName: "オレンジ", in: app)
        createTask("レポート", in: app)
        addCategory(named: "部活", colorName: "紫", in: app)
        createTask("練習", in: app)
        app.buttons["全て"].tap()

        XCTAssertTrue(app.buttons["学校"].exists)
        XCTAssertTrue(app.buttons["部活"].exists)
        XCTAssertTrue(app.staticTexts["レポート"].exists)
        XCTAssertTrue(app.staticTexts["練習"].exists)
    }

    @MainActor
    private func addCategory(named name: String, colorName: String, in app: XCUIApplication) {
        app.buttons["カテゴリを追加"].tap()
        let field = app.textFields["categoryNameField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        // 入力欄を押さなくても、シートを開いただけでキーボードが出ること
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 5))
        field.typeText(name)
        app.buttons[colorName].tap()
        app.buttons["addCategoryButton"].tap()
        XCTAssertTrue(app.buttons[name].waitForExistence(timeout: 5))
    }

    /// タスク画面でタブバーの「作成」から、タイトルだけのタスクを追加する
    @MainActor
    private func createTask(_ title: String, in app: XCUIApplication) {
        tapTab("作成", in: app)
        let field = app.textFields["editorTitleField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        tapAndWaitForKeyboard(field, in: app)
        field.typeText(title)
        app.buttons["editorSaveButton"].tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
    }

    /// シート表示直後はキーボードが出る前に入力すると要素を見失うことがあるため、キーボードの表示を待つ
    @MainActor
    private func tapAndWaitForKeyboard(_ field: XCUIElement, in app: XCUIApplication) {
        field.tap()
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 5))
    }
}
