#if canImport(CarPlay)
import CarPlay
import Foundation
import UIKit

@objc(AutoCarPlaySceneDelegate)
public class AutoCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var templateObserver: NSObjectProtocol?

    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        observeTemplateChanges()
        AutoBridge.shared.setConnected(true)
        reloadTemplate(animated: false)
    }

    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        removeTemplateObserver()
        self.interfaceController = nil
        AutoBridge.shared.setConnected(false)
    }

    private func observeTemplateChanges() {
        removeTemplateObserver()
        templateObserver = NotificationCenter.default.addObserver(
            forName: .capgoAutoTemplateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadTemplate(animated: true)
        }
    }

    private func removeTemplateObserver() {
        if let templateObserver {
            NotificationCenter.default.removeObserver(templateObserver)
        }
        templateObserver = nil
    }

    private func reloadTemplate(animated: Bool) {
        guard let interfaceController else {
            return
        }

        interfaceController.setRootTemplate(makeTemplate(AutoBridge.shared.template), animated: animated, completion: nil)
    }

    private func makeTemplate(_ template: AutoTemplate) -> CPTemplate {
        let sections = makeSections(template)
        return CPListTemplate(title: template.title, sections: sections)
    }

    private func makeSections(_ template: AutoTemplate) -> [CPListSection] {
        if template.sections.isEmpty || template.sections.allSatisfy({ $0.items.isEmpty }) {
            let item = CPListItem(text: template.emptyText, detailText: nil)
            item.isEnabled = false
            return [CPListSection(items: [item])]
        }

        return template.sections.compactMap { section in
            let items = section.items.map(makeListItem)
            guard !items.isEmpty else {
                return nil
            }

            if let header = section.header, !header.isEmpty {
                return CPListSection(items: items, header: header, sectionIndexTitle: nil)
            }

            return CPListSection(items: items)
        }
    }

    private func makeListItem(_ item: AutoTemplateItem) -> CPListItem {
        let listItem = CPListItem(text: item.title, detailText: item.subtitle)
        listItem.isEnabled = item.enabled
        listItem.handler = { _, completion in
            AutoBridge.shared.receiveAction(item)
            completion()
        }
        return listItem
    }
}
#endif
