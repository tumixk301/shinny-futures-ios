//
//  OrderTableViewController.swift
//  shinnyfutures
//
//  Created by chenli on 2018/4/4.
//  Copyright © 2018年 xinyi. All rights reserved.
//

import UIKit
import SwiftyJSON
import DeepDiff

class OrderTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: Properties
    var orders = [JSON]()
    let dataManager = DataManager.getInstance()
    let dateFormat = DateFormatter()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        segmentControl.addTarget(self, action: #selector(segmentValueChange), for: .valueChanged)
        dateFormat.dateFormat = "HH:mm:ss"
    }

    override func viewWillAppear(_ animated: Bool) {
        refreshPage()
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadData), name: Notification.Name(CommonConstants.OrderNotification), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        print("挂单页销毁")
    }

    func refreshPage() {
        loadData()
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return orders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "OrderTableViewCell"

        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? OrderTableViewCell  else {
            fatalError("The dequeued cell is not an instance of OrderTableViewCell.")
        }

        // Fetches the appropriate quote for the data source layout.
        // 切换挂单种类手动reloadData时需要判空
        if orders.count != 0 {
            let order = orders[indexPath.row]

            let instrumentId = order[OrderConstants.instrument_id].stringValue
            if let search = dataManager.sSearchEntities[instrumentId] {
                cell.name.text = search.instrument_name
            } else {
                cell.name.text = instrumentId
            }

            cell.status.text = order[OrderConstants.last_msg].stringValue
            let offset = order[OrderConstants.offset].stringValue
            switch offset {
            case "OPEN":
                cell.offset.text = "开仓"
            case "CLOSETODAY":
                cell.offset.text = "平今"
            case "CLOSEHISTORY":
                cell.offset.text = "平昨"
            case "CLOSE":
                cell.offset.text = "平仓"
            case "FORCECLOSE":
                cell.offset.text = "强平"
            default:
                cell.offset.text = ""
            }
            let direction = order[OrderConstants.direction].stringValue
            switch direction {
            case "BUY":
                cell.offset.textColor = UIColor.red
            case "SELL":
                cell.offset.textColor = UIColor.green
            default:
                cell.offset.textColor = UIColor.red
            }
            let decimal = dataManager.getDecimalByPtick(instrumentId: instrumentId) + 1
            let price = order[OrderConstants.limit_price].stringValue
            cell.price.text = dataManager.saveDecimalByPtick(decimal: decimal, data: price)
            let volume_left = order[OrderConstants.volume_left].intValue
            let volume_origin = order[OrderConstants.volume_orign].intValue
            let volume_trade = volume_origin - volume_left
            cell.volume.text = "\(volume_trade)" + "/" + "\(volume_origin)"
            let trade_time = order[OrderConstants.insert_date_time].doubleValue
            let date = Date(timeIntervalSince1970: (trade_time / 1000000000))
            cell.time.text = dateFormat.string(from: date)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if orders.count != 0 {
            let order = orders[indexPath.row]
            let status = order[OrderConstants.status].stringValue
            if "ALIVE".elementsEqual(status) {
                let order_id = order[OrderConstants.order_id].stringValue
                let instrument_id = order[OrderConstants.instrument_id].stringValue
                let direction_title = order[OrderConstants.direction].stringValue
                let volume = order[OrderConstants.volume_left].stringValue
                let price = order[OrderConstants.limit_price].stringValue
                let title = "您确定要撤单吗？"
                let message = "合约：\(instrument_id), 价格：\(price), 方向：\(direction_title), 手数：\(volume)手"
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in
                    switch action.style {
                    case .default:
                        TDWebSocketUtils.getInstance().sendReqCancelOrder(orderId: order_id)
                    default:
                        break
                    }}))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 35.0))
        headerView.backgroundColor = UIColor.darkGray
        let stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 35.0))
        stackView.distribution = .fillEqually
        let name = UILabel()
        name.textColor = UIColor.white
        name.text = "合约"
        name.textAlignment = .center
        let state = UILabel()
        state.textColor = UIColor.white
        state.text = "状态"
        state.textAlignment = .center
        let direction = UILabel()
        direction.textColor = UIColor.white
        direction.text = "开平"
        direction.textAlignment = .center
        let price = UILabel()
        price.textColor = UIColor.white
        price.text = "委托价"
        price.textAlignment = .center
        let volume = UILabel()
        volume.textColor = UIColor.white
        volume.text = "数量"
        volume.textAlignment = .center
        let time = UILabel()
        time.textColor = UIColor.white
        time.text = "时间"
        time.textAlignment = .center
        stackView.addArrangedSubview(name)
        stackView.addArrangedSubview(state)
        stackView.addArrangedSubview(direction)
        stackView.addArrangedSubview(price)
        stackView.addArrangedSubview(volume)
        stackView.addArrangedSubview(time)
        headerView.addSubview(stackView)
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35.0
    }

    @objc func segmentValueChange() {
        orders.removeAll()
        tableView.reloadData()
        loadData()
    }
    
    // MARK: objc Methods
    @objc private func loadData() {
        if orders.count == 0 {
            if segmentControl.selectedSegmentIndex == 0 {
                orders = dataManager.sRtnOrders.sorted(by: >).map {$0.value}
            } else {
                for order in dataManager.sRtnOrders.sorted(by: >).map({$0.value}) {
                    let status = order[OrderConstants.status].stringValue
                    if "ALIVE".elementsEqual(status){
                        orders.append(order)
                    }
                }
            }
            tableView.reloadData()
        } else {
            let oldData = orders
            if segmentControl.selectedSegmentIndex == 0 {
                orders = dataManager.sRtnOrders.sorted(by: >).map {$0.value}
            } else {
                orders.removeAll()
                for order in dataManager.sRtnOrders.sorted(by: >).map({$0.value}) {
                    let status = order[OrderConstants.status].stringValue
                    if "ALIVE".elementsEqual(status) {
                        orders.append(order)
                    }
                }
            }
            let change = diff(old: oldData, new: orders)
            tableView.reload(changes: change, section: 0, insertionAnimation: .none, deletionAnimation: .none, replacementAnimation: .none, completion: {_ in})
        }
    }

}
