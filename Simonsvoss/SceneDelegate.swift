//
//  SceneDelegate.swift
//  Simonsvoss
//
//  Created by Mohammad Bitar on 7/9/22.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private let navigationController = UINavigationController()
    let remoteClient = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        configureWindow()
    }
    
    func configureWindow() {
        navigationController.setViewControllers([makeRootViewController()], animated: false)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    private func makeRootViewController() -> ListViewController {
        let baseURL = URL(string: "https://simonsvoss-homework.herokuapp.com/sv_lsm_data.json")!
        let loader = RemoteLoader(url: baseURL, client: remoteClient)
        let viewModel = ListViewModel(loader: MainQueueDispatchDecorator(decoratee: loader))
        let viewController = ListViewController(viewModel: viewModel)
        return viewController
    }
}
