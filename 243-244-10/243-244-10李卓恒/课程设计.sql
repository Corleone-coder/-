-- 创建数据库（若未存在）
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'SupermarketSalesDB')
CREATE DATABASE SupermarketSalesDB;
GO

USE SupermarketSalesDB;
GO

-- 1. 角色表
CREATE TABLE sys_role (
    role_id VARCHAR(32) PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    role_desc VARCHAR(200),
    create_time DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- 2. 权限表
CREATE TABLE sys_permission (
    perm_id VARCHAR(32) PRIMARY KEY,
    perm_name VARCHAR(100) NOT NULL UNIQUE,
    perm_desc VARCHAR(200)
);
GO

-- 3. 角色权限关联表
CREATE TABLE sys_role_perm (
    id VARCHAR(32) PRIMARY KEY,
    role_id VARCHAR(32) NOT NULL,
    perm_id VARCHAR(32) NOT NULL,
    FOREIGN KEY (role_id) REFERENCES sys_role(role_id),
    FOREIGN KEY (perm_id) REFERENCES sys_permission(perm_id),
    UNIQUE (role_id, perm_id)
);
GO

-- 4. 用户表
CREATE TABLE sys_user (
    user_id VARCHAR(32) PRIMARY KEY,
    user_name VARCHAR(50) NOT NULL,
    password VARCHAR(64) NOT NULL,
    real_name VARCHAR(50) NOT NULL,
    role_id VARCHAR(32) NOT NULL,
    phone VARCHAR(20) UNIQUE,
    status TINYINT NOT NULL DEFAULT 1, -- 1-正常，0-禁用
    create_time DATETIME NOT NULL DEFAULT GETDATE(),
    update_time DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (role_id) REFERENCES sys_role(role_id)
);
GO

-- 5. 商品分类表
CREATE TABLE goods_category (
    category_id VARCHAR(32) PRIMARY KEY,
    parent_id VARCHAR(32) NOT NULL DEFAULT '0',
    category_name VARCHAR(50) NOT NULL,
    category_level TINYINT NOT NULL, -- 1-课，2-类，3-种
    status TINYINT NOT NULL DEFAULT 1, -- 1-正常，0-已删除
    create_time DATETIME NOT NULL DEFAULT GETDATE(),
    update_time DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (parent_id) REFERENCES goods_category(category_id)
);
GO

-- 6. 货架表
CREATE TABLE goods_shelf (
    shelf_id VARCHAR(32) PRIMARY KEY,
    area_code VARCHAR(20) NOT NULL,
    shelf_code VARCHAR(20) NOT NULL,
    layer_code VARCHAR(20) NOT NULL,
    shelf_desc VARCHAR(200),
    UNIQUE (area_code, shelf_code, layer_code)
);
GO

-- 7. 商品表
CREATE TABLE goods (
    goods_id VARCHAR(32) PRIMARY KEY,
    goods_code VARCHAR(50) NOT NULL UNIQUE,
    category_id VARCHAR(32) NOT NULL,
    goods_name VARCHAR(100) NOT NULL,
    spec VARCHAR(50),
    unit VARCHAR(20) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2) NOT NULL,
    status TINYINT NOT NULL DEFAULT 2, -- 2-待上架，1-在架，0-已下架
    shelf_id VARCHAR(32) NOT NULL,
    create_time DATETIME NOT NULL DEFAULT GETDATE(),
    update_time DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (category_id) REFERENCES goods_category(category_id),
    FOREIGN KEY (shelf_id) REFERENCES goods_shelf(shelf_id)
);
GO

-- 8. 库存表
CREATE TABLE inventory (
    inventory_id VARCHAR(32) PRIMARY KEY,
    goods_id VARCHAR(32) NOT NULL UNIQUE,
    stock_quantity INT NOT NULL DEFAULT 0,
    on_shelf_quantity INT NOT NULL DEFAULT 0,
    warning_quantity INT NOT NULL DEFAULT 10, -- 库存警戒值
    on_shelf_warning INT NOT NULL DEFAULT 5, -- 货架警戒值
    stock_status TINYINT NOT NULL DEFAULT 1, -- 1-充足，0-短缺
    on_shelf_status TINYINT NOT NULL DEFAULT 1, -- 1-充足，0-短缺
    update_time DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (goods_id) REFERENCES goods(goods_id)
);
GO

-- 9. 会员等级表
CREATE TABLE member_level (
    level_id VARCHAR(32) PRIMARY KEY,
    level_name VARCHAR(50) NOT NULL UNIQUE,
    upgrade_points INT NOT NULL, -- 升级所需积分
    upgrade_consume DECIMAL(12,2) NOT NULL, -- 升级所需消费金额
    discount_rate DECIMAL(5,2) NOT NULL, -- 折扣比例（如0.95=9.5折）
    level_desc VARCHAR(200)
);
GO

-- 10. 会员表
CREATE TABLE member (
    member_id VARCHAR(32) PRIMARY KEY,
    member_card VARCHAR(50) NOT NULL UNIQUE,
    member_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) UNIQUE,
    address VARCHAR(200),
    level_id VARCHAR(32) NOT NULL,
    total_consume DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_points INT NOT NULL DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 1, -- 1-正常，0-注销
    create_time DATETIME NOT NULL DEFAULT GETDATE(),
    update_time DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (level_id) REFERENCES member_level(level_id)
);
GO

-- 11. 订单主表
CREATE TABLE order_main (
    order_id VARCHAR(32) PRIMARY KEY,
    member_id VARCHAR(32) NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    actual_amount DECIMAL(10,2) NOT NULL,
    pay_type TINYINT NOT NULL, -- 1-现金，2-银行卡，3-赠券
    order_status TINYINT NOT NULL, -- 0-待结账，1-已完成，2-挂单中，3-已撤销，4-已整单退货，5-部分退货
    cashier_id VARCHAR(32) NOT NULL,
    order_time DATETIME NOT NULL DEFAULT GETDATE(),
    pay_time DATETIME NULL,
    remark VARCHAR(200),
    FOREIGN KEY (member_id) REFERENCES member(member_id),
    FOREIGN KEY (cashier_id) REFERENCES sys_user(user_id)
);
GO

-- 12. 订单明细表
CREATE TABLE order_detail (
    detail_id VARCHAR(32) PRIMARY KEY,
    order_id VARCHAR(32) NOT NULL,
    goods_id VARCHAR(32) NOT NULL,
    goods_name VARCHAR(100) NOT NULL,
    spec VARCHAR(50),
    unit VARCHAR(20) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    return_quantity INT NOT NULL DEFAULT 0,
    return_status TINYINT NOT NULL DEFAULT 0, -- 0-未退货，1-部分退货，2-全部退货
    FOREIGN KEY (order_id) REFERENCES order_main(order_id),
    FOREIGN KEY (goods_id) REFERENCES goods(goods_id)
);
GO

-- 13. 退货单表
CREATE TABLE return_order (
    return_id VARCHAR(32) PRIMARY KEY,
    order_id VARCHAR(32) NOT NULL,
    member_id VARCHAR(32) NULL,
    return_type TINYINT NOT NULL, -- 1-整单退货，2-部分退货
    return_amount DECIMAL(10,2) NOT NULL,
    return_reason TINYINT NOT NULL, -- 1-质量问题，2-7天无理由，3-规格不符，4-损坏
    reason_desc VARCHAR(200),
    return_time DATETIME NOT NULL DEFAULT GETDATE(),
    handler_id VARCHAR(32) NOT NULL,
    refund_type TINYINT NOT NULL, -- 与支付方式一致
    refund_time DATETIME NOT NULL DEFAULT GETDATE(),
    status TINYINT NOT NULL, -- 0-待处理，1-已完成，2-已驳回
    FOREIGN KEY (order_id) REFERENCES order_main(order_id),
    FOREIGN KEY (member_id) REFERENCES member(member_id),
    FOREIGN KEY (handler_id) REFERENCES sys_user(user_id)
);
GO

-- 14. 退货明细表
CREATE TABLE return_detail (
    return_detail_id VARCHAR(32) PRIMARY KEY,
    return_id VARCHAR(32) NOT NULL,
    order_detail_id VARCHAR(32) NOT NULL,
    goods_id VARCHAR(32) NOT NULL,
    return_quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    goods_status TINYINT NOT NULL, -- 1-完好，2-损坏，3-质量问题
    stock_handle TINYINT NOT NULL, -- 1-恢复库存，2-待质检，3-直接下架
    FOREIGN KEY (return_id) REFERENCES return_order(return_id),
    FOREIGN KEY (order_detail_id) REFERENCES order_detail(detail_id),
    FOREIGN KEY (goods_id) REFERENCES goods(goods_id)
);
GO

-- 15. 罚款单表
CREATE TABLE penalty_order (
    penalty_id VARCHAR(32) PRIMARY KEY,
    order_id VARCHAR(32) NULL,
    return_id VARCHAR(32) NULL,
    goods_id VARCHAR(32) NOT NULL,
    member_id VARCHAR(32) NULL,
    penalty_type TINYINT NOT NULL, -- 1-商品损坏，2-商品丢失
    penalty_amount DECIMAL(10,2) NOT NULL,
    penalty_reason VARCHAR(200) NOT NULL,
    pay_status TINYINT NOT NULL DEFAULT 0, -- 0-未支付，1-已支付
    pay_time DATETIME NULL,
    handler_id VARCHAR(32) NOT NULL,
    create_time DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (order_id) REFERENCES order_main(order_id),
    FOREIGN KEY (return_id) REFERENCES return_order(return_id),
    FOREIGN KEY (goods_id) REFERENCES goods(goods_id),
    FOREIGN KEY (member_id) REFERENCES member(member_id),
    FOREIGN KEY (handler_id) REFERENCES sys_user(user_id)
);
GO

-- 创建常用索引（提升查询性能）
CREATE INDEX IX_goods_category ON goods(category_id);
CREATE INDEX IX_order_main_member ON order_main(member_id);
CREATE INDEX IX_order_detail_order ON order_detail(order_id);
CREATE INDEX IX_return_order_order ON return_order(order_id);
GO