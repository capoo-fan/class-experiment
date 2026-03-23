import pandas as pd
import numpy as np


def entropy(data, target_col):
    counts = data[target_col].value_counts()
    p = counts / len(data)
    entropy = -np.sum(p * np.log2(p))
    return entropy


# 计算某一个 feature 的信息增益
def gain(data, feature, target_col):
    total_entropy = entropy(data, target_col)
    values, counts = np.unique(data[feature], return_counts=True)

    weighted_entropy = 0
    for i in range(len(values)):
        subset = data[data[feature] == values[i]]
        weight = counts[i] / np.sum(counts)
        weighted_entropy += weight * entropy(subset, target_col)

    gain = total_entropy - weighted_entropy
    return gain


def build_tree(data, features, target_col):
    if len(np.unique(data[target_col])) == 1:
        return np.unique(data[target_col])[0]

    # 返回最多数的类别
    if len(features) == 0:
        return data[target_col].mode()[0]

    gains = [gain(data, feature, target_col) for feature in features]
    best_feature_idx = np.argmax(gains)
    best_feature = features[best_feature_idx]

    tree = {best_feature: {"__default__": data[target_col].mode()[0]}}

    remain_features = [f for f in features if f != best_feature]

    for value in np.unique(data[best_feature]):
        subset = data[data[best_feature] == value]
        if len(subset) == 0:
            tree[best_feature][value] = data[target_col].mode()[0]
        else:
            tree[best_feature][value] = build_tree(
                subset, remain_features, target_col
            )
    return tree


def predict(tree, instance):
    if not isinstance(tree, dict):
        return tree

    feature = next(iter(tree))
    feature_value = instance[feature]

    if feature_value in tree[feature]:
        return predict(tree[feature][feature_value], instance)

    return tree[feature].get("__default__", np.nan)


if __name__ == "__main__":
    train_data = pd.read_csv("Data/train.csv")
    predict_data = pd.read_csv("Data/predict.csv")

    target = "weather"
    features = train_data.columns.tolist()
    features.remove(target)

    decision_tree = build_tree(train_data, features, target)
    print(decision_tree)

    predictions = []
    for _, row in predict_data.iterrows():
        pred_label = predict(decision_tree, row)
        predictions.append(pred_label)

    predict_data["weather"] = predictions
    predict_data.to_csv("result.csv", index=False)
    print("结果储存到 result.csv")
